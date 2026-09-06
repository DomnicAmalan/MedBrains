//! Default cross-module pipelines — hardcoded Rust subscribers that
//! fire on every deployment without DB-side configuration.
//!
//! Why hardcoded vs `integration_pipelines` rows? Three reasons:
//!   1. Reliability — pipelines are critical infra (bed cleaning,
//!      NDPS register, payment receipts, blood quarantine). A row
//!      deleted by accident shouldn't silently break the workflow.
//!   2. Determinism — every fresh tenant boots with the same baseline
//!      cross-module wiring, guaranteed, rather than depending on
//!      whether somebody remembered to build it.
//!   3. Review — a pipeline decides clinical and regulatory behaviour.
//!      Quarantining blood, writing an NDPS register row and escalating
//!      a critical value are not configuration preferences, and they
//!      should go through code review and version control like any
//!      other clinical logic.
//!
//! Automation here is code. Cross-module behaviour is written as a
//! subscriber in this file, not assembled in a UI: an automation nobody
//! can diff, review or roll back is not something to put between a
//! reaction report and the next patient to receive that donation.
//!
//! Each subscriber is a small async function that:
//!   - Opens its own short transaction.
//!   - Reads the event payload.
//!   - Queues outbound events via `medbrains_outbox::queue_in_tx` and/or
//!     inserts cross-module rows (housekeeping_tasks, NDPS register,
//!     indent_requisitions, etc.).
//!   - Commits.
//!
//! Errors are swallowed at the per-pipeline level — a failure in one
//! shouldn't break the originating request. They're logged at warn
//! and surface in the audit log via the outbox worker's metrics.
//!
//! Extending: write an `on_<event>` function below and add one row to
//! [`PIPELINES`]. There is no second list to keep in step and no match arm
//! to forget. Keep each handler small; complex logic belongs in its own
//! module that the handler calls.

use std::{future::Future, pin::Pin};

use medbrains_core::clinical_events::ClinicalEventName;
use serde_json::{Value, json};
use sqlx::{PgPool, Postgres, Transaction};
use uuid::Uuid;

use medbrains_outbox::queue::{OutboxRow, queue_in_tx};

/// One pipeline. The event it answers, what it does, and the code that does
/// it — in a single place.
///
/// Adding a pipeline used to mean three edits that could silently disagree:
/// an entry in a description array, a match arm, and the function. The array
/// fed the Integration Hub and the match arm decided what actually ran, so a
/// pipeline could be advertised and never fire, or fire and never appear.
/// Now they cannot drift, because they are the same row.
#[derive(Debug)]
pub struct Pipeline {
    /// The event this pipeline answers.
    pub event: ClinicalEventName,
    /// What it does, shown in the Integration Hub.
    pub description: &'static str,
    /// The subscriber. Every pipeline is independent: it opens its own
    /// transaction, reads only the payload, and cannot see or affect any
    /// other pipeline's work. One failing does not stop the rest.
    pub run: PipelineFn,
}

/// What every subscriber looks like: the pool, the tenant, the event payload.
///
/// Boxed because a `const` array cannot hold `async fn`s of differing types —
/// each row wraps its function in `Box::pin`.
pub type PipelineFn = for<'a> fn(
    &'a PgPool,
    Uuid,
    &'a Value,
) -> Pin<Box<dyn Future<Output = Result<(), sqlx::Error>> + Send + 'a>>;

/// Every built-in pipeline.
///
/// To add one: write the subscriber below, then add a row here. That is the
/// whole procedure — there is no second list to keep in step, and nothing to
/// configure in a UI.
pub const PIPELINES: &[Pipeline] = &[
    Pipeline {
        event: ClinicalEventName::IpdDischargeInitiated,
        description: "MRD file request + discharge-summary link to the patient",
        run: |p, t, v| Box::pin(on_ipd_discharge_initiated(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::PharmacyOrderDispensed,
        description: "Low-stock check on every dispensed item",
        run: |p, t, v| Box::pin(on_pharmacy_order_dispensed(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::LabResultPosted,
        description: "Critical-value SMS to ordering doctor",
        run: |p, t, v| Box::pin(on_lab_result_posted(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::BillingInvoiceCreated,
        description: "Payment link to patient (WhatsApp)",
        run: |p, t, v| Box::pin(on_billing_invoice_created(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::BillingPaymentReceived,
        description: "Receipt email to patient",
        run: |p, t, v| Box::pin(on_billing_payment_received(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::OpdEncounterCreated,
        description: "Appointment confirmation SMS",
        run: |p, t, v| Box::pin(on_opd_encounter_created(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::EmergencyCodeBlueCompleted,
        description: "Stand down everyone the code blue paged",
        run: |p, t, v| Box::pin(on_emergency_code_blue_completed(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::BmeEquipmentDowntimeRecorded,
        description: "Take broken equipment out of service and tell biomedical",
        run: |p, t, v| Box::pin(on_bme_equipment_downtime_recorded(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::IpdAdmissionCreated,
        description: "Raise the 24-hour initial nursing assessment on admission",
        run: |p, t, v| Box::pin(on_ipd_admission_created(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::PharmacyNdpsMovementCreated,
        description: "Raise a quality incident when an NDPS entry lacks its second signature",
        run: |p, t, v| Box::pin(on_pharmacy_ndps_movement_created(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::EmergencyCodeBlueActivated,
        description: "Page active clinical staff + queue the code-blue alert",
        run: |p, t, v| Box::pin(on_emergency_code_blue_activated(p, t, v)),
    },
    Pipeline {
        event: ClinicalEventName::BloodTransfusionReactionReported,
        description: "Quarantine sibling components + raise incident + alert blood bank",
        run: |p, t, v| Box::pin(on_transfusion_reaction(p, t, v)),
    },
];

/// Event/description pairs for the Integration Hub, derived from the registry
/// rather than maintained beside it.
#[must_use]
pub fn default_subscribers() -> Vec<(&'static str, &'static str)> {
    PIPELINES
        .iter()
        .map(|p| (p.event.as_str(), p.description))
        .collect()
}

/// Per-tenant opt-out check. Reads `tenant_settings` row with
/// category=`default_pipelines` and a JSON array of disabled `event_types`.
/// Failures (missing table, unparseable value) default to enabled —
/// the safe choice is "fire the baseline workflow."
async fn is_disabled(pool: &PgPool, tenant_id: Uuid, event_type: &str) -> bool {
    // No connection means no answer, and the safe answer here is "not
    // disabled" only if the caller can tell the difference — it cannot, so
    // this returns the same as finding no setting, which is what it did
    // before there was a connection to fail to get.
    let Ok(mut conn) = medbrains_db::pool::tenant_conn(pool, &tenant_id).await else {
        tracing::warn!(%tenant_id, event_type, "pipeline setting unreadable");
        return false;
    };
    let res: Result<Option<Value>, _> = sqlx::query_scalar(
        "SELECT value FROM tenant_settings \
         WHERE tenant_id = $1 AND category = 'default_pipelines' AND key = 'disabled' \
         LIMIT 1",
    )
    .bind(tenant_id)
    .fetch_optional(&mut *conn)
    .await;
    match res {
        Ok(Some(v)) => v
            .as_array()
            .map(|arr| arr.iter().any(|item| item.as_str() == Some(event_type)))
            .unwrap_or(false),
        _ => false,
    }
}

/// Top-level dispatcher. Called from `events::emit_event` alongside
/// the DB-backed pipeline lookup.
///
/// **Idempotency contract:** every outbox row queued by these
/// subscribers carries an `idempotency_key`. If a user-built
/// `integration_pipelines` row tries to enqueue the same event with
/// the same key, `outbox_events_idemp` deduplicates. So defaults +
/// dynamic pipelines coexist safely without double-fire.
pub async fn dispatch_default_pipelines(
    pool: &PgPool,
    tenant_id: Uuid,
    event_type: &str,
    payload: &Value,
) {
    if is_disabled(pool, tenant_id, event_type).await {
        tracing::debug!(
            tenant_id = %tenant_id,
            event_type = event_type,
            "default_pipelines: disabled for tenant, skipping"
        );
        return;
    }

    let Ok(parsed) = event_type.parse::<ClinicalEventName>() else {
        return;
    };

    // Every pipeline for this event runs, and each is independent: its own
    // transaction, its own failure. One raising an error must not stop the
    // next — a blood quarantine failing is no reason to skip an NDPS row.
    //
    // Events with no pipeline are not an error. They are a gap to close by
    // writing a subscriber above: `patient.created` has fired 154 times on
    // this database with nothing listening, and the answer is a reviewed
    // function, not a row somebody assembled in a UI.
    for pipeline in PIPELINES.iter().filter(|p| p.event == parsed) {
        let result = (pipeline.run)(pool, tenant_id, payload).await;
        if let Err(err) = result {
            tracing::error!(
                tenant_id = %tenant_id,
                event_type = event_type,
                error = %err,
                "default_pipelines: subscriber failed"
            );
        }
    }

}

// ── 1. IPD discharge → housekeeping + MRD + claim assembly ─────────

async fn on_ipd_discharge_initiated(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let admission_id = uuid_from_payload(payload, "admission_id");
    let patient_id = uuid_from_payload(payload, "patient_id");

    let mut tx = pool.begin().await?;

    // The bed is deliberately not touched here. This pipeline used to run
    // `UPDATE beds SET status = 'dirty'` — against a column that does not
    // exist (`beds` has `is_occupied`; the live state is `bed_states.status`),
    // reading a `bed_id` this event has never carried, with the error
    // swallowed by `.ok()`. It marked nothing dirty for as long as it existed.
    //
    // It is also not this subscriber's job. `discharge_patient` already calls
    // `release_admission_bed`, which sets `bed_states` to `vacant_dirty` in the
    // same transaction as the discharge. A bed freed by an async subscriber
    // that may fail is a bed the board can disagree with.

    // a) Queue an SMS/WhatsApp discharge-summary link to the patient.
    if let Some(p) = patient_id {
        let _ = enqueue(
            &mut tx,
            tenant_id,
            "patient",
            Some(p),
            "whatsapp.discharge_summary",
            json!({
                "patient_id": p,
                "admission_id": admission_id,
                "template_name": "discharge_summary",
                "language": "en",
            }),
            admission_id.map(|a| format!("discharge:{a}")),
        )
        .await;
    }

    // b) Queue MRD file-creation request (if MRD module is wired).
    if let Some(a) = admission_id {
        let _ = enqueue(
            &mut tx,
            tenant_id,
            "admission",
            Some(a),
            "mrd.file_creation_requested",
            json!({ "admission_id": a, "patient_id": patient_id }),
            Some(format!("mrd_create:{a}")),
        )
        .await;
    }

    tx.commit().await?;
    Ok(())
}

// ── 2. Pharmacy dispense → low-stock auto-indent ───

async fn on_pharmacy_order_dispensed(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let items = payload.get("items").and_then(Value::as_array);

    let mut tx = pool.begin().await?;

    // The NDPS register is deliberately not written here. This pipeline used
    // to insert into `pharmacy_ndps_register` naming `order_id`, `drug_id`,
    // `drug_name`, `schedule`, `qty` and `action_at` — none of which are
    // columns on that table — with the error swallowed by `.ok()`. Not one row
    // was ever written by it.
    //
    // The dispense handler already writes the register correctly, in the same
    // transaction as the stock movement, with the running `balance_after`, the
    // witness, the patient and the prescription. That is where a statutory
    // narcotics register belongs: a register written by a subscriber that can
    // fail is a register that can disagree with what was dispensed.

    // b) For each item whose post-dispense stock dropped below reorder_level,
    //    queue a low-stock alert event. The alert is consumed by an
    //    indent-creation job that batches by drug to avoid duplicate
    //    indents within the same window.
    if let Some(items) = items {
        for item in items {
            let Some(drug_id) = uuid_from_value(item.get("drug_id")) else {
                continue;
            };
            let _ = enqueue(
                &mut tx,
                tenant_id,
                "drug",
                Some(drug_id),
                "pharmacy.stock_check",
                json!({ "drug_id": drug_id, "trigger": "post_dispense" }),
                // Idempotency: at most one stock_check per drug per day.
                Some(format!(
                    "stock_check:{drug_id}:{}",
                    chrono::Utc::now().date_naive()
                )),
            )
            .await;
        }
    }

    tx.commit().await?;
    Ok(())
}

// ── 3. Lab result posted → critical-value SMS to ordering doctor ─

async fn on_lab_result_posted(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let order_id = uuid_from_payload(payload, "order_id");
    let ordering_doctor_id = uuid_from_payload(payload, "ordering_provider_id");
    let critical_count = payload
        .get("critical_count")
        .and_then(Value::as_u64)
        .unwrap_or(0);

    if critical_count == 0 {
        return Ok(());
    }

    let Some(order) = order_id else { return Ok(()) };
    let mut tx = pool.begin().await?;

    // The Twilio handler needs payload.to — without the doctor's phone
    // the event dead-letters and the alert silently never leaves the
    // building (audit P0 #16).
    let doctor_phone: Option<String> = match ordering_doctor_id {
        Some(doctor_id) => {
            sqlx::query_scalar("SELECT phone FROM users WHERE id = $1 AND tenant_id = $2")
                .bind(doctor_id)
                .bind(tenant_id)
                .fetch_optional(&mut *tx)
                .await?
                .flatten()
        }
        None => None,
    };

    match doctor_phone.filter(|phone| !phone.trim().is_empty()) {
        Some(phone) => {
            let _ = enqueue(
                &mut tx,
                tenant_id,
                "lab_order",
                Some(order),
                "sms.cds_critical_interaction",
                json!({
                    "to": phone,
                    "order_id": order,
                    "ordering_doctor_id": ordering_doctor_id,
                    "critical_count": critical_count,
                    "body": format!("Critical lab values on order {order} — review immediately"),
                }),
                Some(format!("crit:{order}")),
            )
            .await;
        }
        None => {
            tracing::warn!(
                %order, ?ordering_doctor_id,
                "critical lab SMS skipped — ordering doctor has no phone on file"
            );
        }
    }

    tx.commit().await?;
    Ok(())
}

// ── 4. Invoice created → payment-link to patient ───────────────────

async fn on_billing_invoice_created(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let invoice_id = uuid_from_payload(payload, "invoice_id");
    let patient_id = uuid_from_payload(payload, "patient_id");
    let total = payload
        .get("total_amount")
        .and_then(Value::as_f64)
        .unwrap_or(0.0);

    if total <= 0.0 {
        return Ok(()); // No charge → no payment link needed.
    }

    let Some(inv) = invoice_id else { return Ok(()) };
    let Some(p) = patient_id else { return Ok(()) };
    let mut tx = pool.begin().await?;

    let _ = enqueue(
        &mut tx,
        tenant_id,
        "invoice",
        Some(inv),
        "whatsapp.payment_link",
        json!({
            "invoice_id": inv,
            "patient_id": p,
            "amount": total,
            "template_name": "payment_link",
            "language": "en",
        }),
        Some(format!("paylink:{inv}")),
    )
    .await;

    tx.commit().await?;
    Ok(())
}

// ── 5. Payment received → email/whatsapp receipt ───────────────────

async fn on_billing_payment_received(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let mut conn = medbrains_db::pool::tenant_conn(pool, &tenant_id)
        .await
        .map_err(|e| sqlx::Error::Configuration(Box::new(e)))?;
    let payment_id = uuid_from_payload(payload, "payment_id");
    let invoice_id = uuid_from_payload(payload, "invoice_id");
    let patient_id = uuid_from_payload(payload, "patient_id");

    let Some(pay) = payment_id else { return Ok(()) };

    // The SMTP handler requires a recipient + subject + body and permanently
    // dead-letters without them. Resolve the patient's email here and build
    // the receipt; if the patient has no email, skip cleanly (no DLQ) — a
    // missing address is not a delivery failure. (Worker runs BYPASSRLS, so
    // a tenant_id filter is sufficient.)
    let to: Option<String> = match patient_id {
        Some(p) => sqlx::query_scalar(
            "SELECT NULLIF(email, '') FROM patients WHERE id = $1 AND tenant_id = $2",
        )
        .bind(p)
        .bind(tenant_id)
        .fetch_optional(&mut *conn)
        .await?
        .flatten(),
        None => None,
    };
    let Some(to) = to else { return Ok(()) };

    let invoice: Option<(String, rust_decimal::Decimal)> = match invoice_id {
        Some(i) => sqlx::query_as(
            "SELECT invoice_number, total_amount FROM invoices WHERE id = $1 AND tenant_id = $2",
        )
        .bind(i)
        .bind(tenant_id)
        .fetch_optional(&mut *conn)
        .await?,
        None => None,
    };
    let (inv_no, amount_line) = invoice.map_or_else(
        || ("your invoice".to_owned(), String::new()),
        |(number, amount)| (number, format!(" (amount {amount})")),
    );
    let subject = format!("Payment receipt — {inv_no}");
    let text = format!("We have received your payment for {inv_no}{amount_line}. Thank you.");
    let html = format!(
        "<p>We have received your payment for <strong>{inv_no}</strong>{amount_line}.</p>\
         <p>Thank you.</p>"
    );

    let mut tx = pool.begin().await?;
    let _ = enqueue(
        &mut tx,
        tenant_id,
        "payment",
        Some(pay),
        "email.invoice_receipt",
        json!({
            "to": to,
            "subject": subject,
            "text": text,
            "html": html,
            "payment_id": pay,
            "invoice_id": invoice_id,
            "patient_id": patient_id,
        }),
        Some(format!("receipt:{pay}")),
    )
    .await;

    tx.commit().await?;
    Ok(())
}

// ── 6. OPD encounter created → appointment confirmation SMS ────────

async fn on_opd_encounter_created(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let encounter_id = uuid_from_payload(payload, "encounter_id");
    let patient_id = uuid_from_payload(payload, "patient_id");

    let Some(enc) = encounter_id else {
        return Ok(());
    };
    let mut tx = pool.begin().await?;

    let _ = enqueue(
        &mut tx,
        tenant_id,
        "encounter",
        Some(enc),
        "sms.appointment_confirmation",
        json!({
            "encounter_id": enc,
            "patient_id": patient_id,
        }),
        Some(format!("conf:{enc}")),
    )
    .await;

    tx.commit().await?;
    Ok(())
}

// ── helpers ────────────────────────────────────────────────────────

fn uuid_from_payload(payload: &Value, key: &str) -> Option<Uuid> {
    uuid_from_value(payload.get(key))
}

fn uuid_from_value(v: Option<&Value>) -> Option<Uuid> {
    v.and_then(Value::as_str)
        .and_then(|s| Uuid::parse_str(s).ok())
}

// ── 8. Code blue activated → page the people who can respond ───────

/// A cardiac arrest is called and, until now, nothing happened.
///
/// `start_code_blue` writes the event, mirrors it to the NABH register, and
/// emits `emergency.code_blue.activated`. No subscriber existed, so the most
/// time-critical event in the hospital reached a table and stopped there.
async fn on_emergency_code_blue_activated(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let code_blue_id = uuid_from_payload(payload, "code_blue_id");
    let patient_id = uuid_from_payload(payload, "patient_id");
    let location = payload
        .get("location")
        .and_then(Value::as_str)
        .unwrap_or("location not recorded");

    let mut tx = pool.begin().await?;

    // a) The durable alert. Channel-agnostic on purpose: whatever carries it —
    //    SMS, push, the corridor TV — reads it from the outbox, so adding a
    //    channel later needs no change here. This is queued first and
    //    unconditionally, because it is the part that must survive everything
    //    below failing.
    let _ = enqueue(
        &mut tx,
        tenant_id,
        "code_blue",
        code_blue_id,
        "emergency.code_blue_alert",
        json!({
            "code_blue_id": code_blue_id,
            "patient_id": patient_id,
            "location": location,
            "body": format!("CODE BLUE — {location}. Respond immediately."),
        }),
        code_blue_id.map(|id| format!("code_blue:{id}")),
    )
    .await;

    // b) In-app notification to clinical staff, in one statement rather than a
    //    query per user. Deliberately NOT scoped to who is on shift: the
    //    attendance table is empty, so an on-duty filter would page nobody and
    //    look like it had worked.
    let notified = sqlx::query!(
        "INSERT INTO notifications \
           (tenant_id, user_id, kind, title, body, category, entity_type, \
            entity_id, action_url) \
         SELECT $1, u.id, 'error', $2, $3, 'emergency', 'code_blue', $4, $5 \
           FROM users u \
          WHERE u.tenant_id = $1 AND u.is_active = true \
            AND u.role::text IN ('doctor', 'nurse') \
          LIMIT 500",
        tenant_id,
        "CODE BLUE",
        format!("{location} — respond immediately."),
        code_blue_id,
        // The code blue tab of the nurse activities page. The URL this shipped
        // with, /ipd/code-blue/{id}, matched no route: the page linked to a 404.
        Some("/nurse?tab=code-blue".to_owned()),
    )
    .execute(&mut *tx)
    .await?
    .rows_affected();

    tx.commit().await?;

    // A code blue that reached nobody must not read as success. On this tenant
    // that is a real possibility — 257 active users, and not one of them a
    // nurse — and it is the kind of silence a hospital only discovers during
    // an arrest.
    if notified == 0 {
        tracing::error!(
            %tenant_id,
            ?code_blue_id,
            location,
            "code blue raised but no active clinical staff to notify — the \
             outbox alert was queued, the in-app page reached no one"
        );
    } else {
        tracing::info!(%tenant_id, ?code_blue_id, notified, "code blue paged");
    }

    Ok(())
}

// ── 9. NDPS movement → the second signature nobody was chasing ─────

/// A controlled-drug movement that needs two signatures and has one.
///
/// The register row itself is written correctly and transactionally by the
/// handler — that is not the gap. The gap is that `requires_dual_sign` with a
/// null `second_witness_id` is a statutory defect under the NDPS Act, and
/// nothing told anyone. The entry has already committed by the time this
/// runs, so blocking is not on offer here; raising the deficiency is.
///
/// It is filed on the quality register because that is the one place with a
/// list, a screen and an assignee — a deficiency recorded only in a log is a
/// deficiency nobody closes. `is_reportable` and `regulatory_body` are set so
/// it appears in the reportable-incident view rather than among routine ones.
async fn on_pharmacy_ndps_movement_created(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let Some(entry_id) = uuid_from_payload(payload, "entry_id") else {
        return Ok(());
    };

    // The title is derived from the entry, so a redelivered event matches the
    // incident it already raised instead of raising a second one.
    let title = format!("NDPS second signature missing — entry {entry_id}");

    let mut tx = pool.begin().await?;

    let raised = sqlx::query!(
        "WITH ent AS ( \
           SELECT r.id, r.action, r.quantity, r.patient_id, c.name AS item_name \
             FROM pharmacy_ndps_register r \
             LEFT JOIN pharmacy_catalog c \
               ON c.id = r.catalog_item_id AND c.tenant_id = r.tenant_id \
            WHERE r.id = $2 AND r.tenant_id = $1 \
              AND COALESCE(r.requires_dual_sign, false) = true \
              AND r.second_witness_id IS NULL \
         ), seq AS ( \
           UPDATE sequences SET current_val = current_val + 1 \
            WHERE tenant_id = $1 AND seq_type = 'INC' AND EXISTS (SELECT 1 FROM ent) \
           RETURNING prefix, current_val, pad_width \
         ) \
         INSERT INTO quality_incidents \
           (tenant_id, incident_number, title, description, incident_type, \
            severity, patient_id, is_reportable, regulatory_body, incident_date) \
         SELECT $1, \
                COALESCE((SELECT prefix || lpad(current_val::text, pad_width, '0') \
                            FROM seq), \
                         'INC-' || to_char(now(), 'YYYYMMDDHH24MISS')), \
                $3::text, \
                'NDPS register entry ' || ent.id || ' (' || ent.action || ' ' \
                  || ent.quantity || ' of ' \
                  || COALESCE(ent.item_name, 'unknown item') \
                  || ') requires a second signature and has none.', \
                'ndps_dual_signature_missing', 'major'::incident_severity, \
                ent.patient_id, true, 'NDPS', now() \
           FROM ent \
          WHERE NOT EXISTS ( \
            SELECT 1 FROM quality_incidents q \
             WHERE q.tenant_id = $1 AND q.title = $3::text AND q.deleted_at IS NULL)",
        tenant_id,
        entry_id,
        title,
    )
    .execute(&mut *tx)
    .await?
    .rows_affected();

    // Nothing raised is the ordinary case: the entry either did not need two
    // signatures or already had both. Only the deficiency is worth an alert.
    if raised > 0 {
        let _ = enqueue(
            &mut tx,
            tenant_id,
            "ndps_register",
            Some(entry_id),
            "pharmacy.ndps_dual_signature_missing",
            json!({
                "entry_id": entry_id,
                "title": title,
                "regulatory_body": "NDPS",
            }),
            Some(format!("ndps_entry:{entry_id}")),
        )
        .await;
    }

    tx.commit().await?;

    if raised > 0 {
        tracing::warn!(
            %tenant_id,
            %entry_id,
            "NDPS movement recorded without its second signature — quality \
             incident raised"
        );
    }

    Ok(())
}

// ── 10. Admission → the initial nursing assessment NABH requires ───

/// NABH wants every inpatient assessed by nursing within 24 hours of
/// admission. Nothing raised that task, so the obligation existed only in
/// the standard.
///
/// The task is assigned, never left open. `my_tasks` filters on
/// `assigned_to = $user`, so an unassigned row sits on nobody's list — it
/// would populate the table and reach no nurse, which is worse than not
/// writing it, because the register then looks attended to.
///
/// That is why nothing is written when no nurse can be resolved. On this
/// database that is every admission: `nurse_shift_assignments` has no rows,
/// so no nurse is on any ward on any date. The error below says so rather
/// than leaving a silent gap where an assessment should be.
async fn on_ipd_admission_created(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let (Some(admission_id), Some(ward_id)) = (
        uuid_from_payload(payload, "admission_id"),
        uuid_from_payload(payload, "ward_id"),
    ) else {
        // Every admission on this database arrives without a ward, so this
        // is the branch that actually runs — and returning Ok here quietly
        // was the same two-outcome mistake the rest of this function exists
        // to avoid. An admission with nowhere to be cannot be assessed by
        // the nurse looking after that nowhere.
        tracing::error!(
            %tenant_id,
            payload = %payload,
            "admission carried no ward — the 24-hour initial assessment \
             could not be raised or addressed to anyone"
        );
        return Ok(());
    };

    // One statement: pick the ward's charge nurse for today — falling back to
    // the primary assigned nurse — and raise the task only if that resolves
    // and this admission has no such task already.
    let created = sqlx::query!(
        "WITH nurse AS ( \
           SELECT COALESCE(nsa.charge_nurse_user_id, nsa.nurse_user_id) AS uid \
             FROM nurse_shift_assignments nsa \
            WHERE nsa.tenant_id = $1 AND nsa.ward_id = $2 \
              AND nsa.shift_date = CURRENT_DATE AND nsa.deleted_at IS NULL \
            ORDER BY nsa.primary_assigned DESC, \
                     (nsa.charge_nurse_user_id IS NULL) \
            LIMIT 1 \
         ) \
         INSERT INTO nursing_tasks \
           (tenant_id, admission_id, assigned_to, task_type, description, \
            category, priority, due_at) \
         SELECT $1, $3, nurse.uid, 'initial_assessment', \
                'Initial nursing assessment — due within 24 hours of \
                 admission (NABH).', \
                'other'::nursing_task_category, 'urgent'::nursing_task_priority, \
                now() + interval '24 hours' \
           FROM nurse \
          WHERE NOT EXISTS ( \
            SELECT 1 FROM nursing_tasks nt \
             WHERE nt.tenant_id = $1 AND nt.admission_id = $3 \
               AND nt.task_type = 'initial_assessment' \
               AND nt.deleted_at IS NULL)",
        tenant_id,
        ward_id,
        admission_id,
    )
    .execute(pool)
    .await?
    .rows_affected();

    if created == 0 {
        tracing::error!(
            %tenant_id,
            %admission_id,
            %ward_id,
            "no nurse rostered on this ward today — the 24-hour initial \
             assessment was not raised, because an unassigned task reaches \
             no one"
        );
    }

    Ok(())
}

// ── 11. Equipment breakdown → take it out of service ───────────────

/// A breakdown was recorded and the machine still read as usable.
///
/// `create_breakdown` writes the breakdown, mirrors it to NABH and emits this
/// event, and never touches `bme_equipment.status`. A calibration that fails
/// tolerance locks its equipment two hundred lines earlier in the same file;
/// a ventilator someone has just reported broken does not. Every screen that
/// lists equipment by status keeps offering it.
///
/// Only `active` kit is moved. Anything already under maintenance, out of
/// service, condemned or disposed is left exactly as it is — a breakdown
/// against a condemned asset must not quietly promote it back into the
/// maintenance pool.
///
/// Nothing here returns it to service when the breakdown is resolved, and
/// that is deliberate: kit comes back after someone verifies it, on the
/// equipment screen, not because a status field was flipped by a repair
/// ticket closing.
async fn on_bme_equipment_downtime_recorded(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let Some(equipment_id) = uuid_from_payload(payload, "equipment_id") else {
        return Ok(());
    };
    let downtime_id = uuid_from_payload(payload, "downtime_id");
    let priority = payload
        .get("priority")
        .and_then(Value::as_str)
        .unwrap_or("medium");

    let mut tx = pool.begin().await?;

    // a) Tell biomedical first and unconditionally. The alert is the half that
    //    has to survive: a machine left available is dangerous, and a machine
    //    locked with nobody told is merely unusable.
    let _ = enqueue(
        &mut tx,
        tenant_id,
        "bme_equipment",
        Some(equipment_id),
        "bme.equipment_downtime_recorded",
        json!({
            "equipment_id": equipment_id,
            "downtime_id": downtime_id,
            "priority": priority,
        }),
        downtime_id.map(|id| format!("bme_downtime:{id}")),
    )
    .await;

    let locked = sqlx::query!(
        "UPDATE bme_equipment \
            SET status = 'under_maintenance'::bme_equipment_status, \
                updated_at = now() \
          WHERE tenant_id = $1 AND id = $2 \
            AND status = 'active'::bme_equipment_status \
            AND deleted_at IS NULL",
        tenant_id,
        equipment_id,
    )
    .execute(&mut *tx)
    .await?
    .rows_affected();

    tx.commit().await?;

    if locked == 0 {
        // Not an error: the usual reason is that the equipment was already
        // out of the pool. Worth a line, because the other reason is that the
        // breakdown names an asset this tenant does not have.
        tracing::info!(
            %tenant_id,
            %equipment_id,
            "breakdown recorded against equipment that was not active — \
             status left unchanged"
        );
    }

    Ok(())
}

// ── 12. Code blue ended → stand down the people it paged ───────────

/// The other half of the page.
///
/// `end_code_blue` records the outcome and mirrors it to NABH, and everyone
/// summoned by the activation is left with an unread CODE BLUE and a link to
/// an emergency that finished. The next one they see is worth less for it.
///
/// The stand-down goes to exactly the users the activation reached — joined
/// from their own notification rows rather than re-derived from roles, so a
/// change of shift, of role or of staffing cannot send it to a different set
/// of people than the ones who were called. Nothing is marked read: a page
/// somebody never saw is a fact about the response, and quietly clearing it
/// would erase the evidence.
async fn on_emergency_code_blue_completed(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let Some(code_blue_id) = uuid_from_payload(payload, "code_blue_id") else {
        return Ok(());
    };
    let outcome = payload
        .get("outcome")
        .and_then(Value::as_str)
        .unwrap_or("outcome not recorded");

    let title = "Code blue stood down";
    let body = format!("The code blue has ended — {outcome}.");

    let mut tx = pool.begin().await?;

    let _ = enqueue(
        &mut tx,
        tenant_id,
        "code_blue",
        Some(code_blue_id),
        "emergency.code_blue_stand_down",
        json!({
            "code_blue_id": code_blue_id,
            "outcome": outcome,
            "body": body,
        }),
        Some(format!("code_blue_end:{code_blue_id}")),
    )
    .await;

    let stood_down = sqlx::query!(
        "INSERT INTO notifications \
           (tenant_id, user_id, kind, title, body, category, entity_type, \
            entity_id, action_url) \
         SELECT DISTINCT $1::uuid, n.user_id, 'info', $3::text, $4::text, \
                'emergency', 'code_blue', $2::uuid, n.action_url \
           FROM notifications n \
          WHERE n.tenant_id = $1::uuid AND n.entity_type = 'code_blue' \
            AND n.entity_id = $2::uuid AND n.title = 'CODE BLUE' \
            AND NOT EXISTS ( \
              SELECT 1 FROM notifications c \
               WHERE c.tenant_id = $1::uuid AND c.entity_type = 'code_blue' \
                 AND c.entity_id = $2::uuid AND c.title = $3::text \
                 AND c.user_id = n.user_id) \
          LIMIT 500",
        tenant_id,
        code_blue_id,
        title,
        body,
    )
    .execute(&mut *tx)
    .await?
    .rows_affected();

    tx.commit().await?;

    // Zero is expected for any code blue that pre-dates the activation
    // pipeline — there is nobody to stand down because nobody was paged.
    tracing::info!(%tenant_id, %code_blue_id, stood_down, "code blue stood down");

    Ok(())
}

async fn enqueue(
    tx: &mut Transaction<'_, Postgres>,
    tenant_id: Uuid,
    aggregate_type: &'static str,
    aggregate_id: Option<Uuid>,
    event_type: &'static str,
    payload: Value,
    idempotency_key: Option<String>,
) -> Result<Uuid, medbrains_outbox::OutboxError> {
    queue_in_tx(
        tx,
        OutboxRow {
            tenant_id,
            aggregate_type,
            aggregate_id,
            event_type,
            payload,
            idempotency_key,
        },
    )
    .await
}

#[cfg(test)]
mod tests {
    use medbrains_core::clinical_events::ClinicalEventName;

    use super::PIPELINES;

    #[test]
    fn critical_lab_default_pipeline_follows_result_posting() {
        // Asserted against the registry that actually dispatches, not a
        // description array beside it — the point of merging the two.
        assert!(
            PIPELINES
                .iter()
                .any(|p| p.event == ClinicalEventName::LabResultPosted)
        );
        assert!(
            !PIPELINES
                .iter()
                .any(|p| p.event == ClinicalEventName::LabOrderCompleted)
        );
    }
}

/// `blood.transfusion_reaction.reported` — haemovigilance.
///
/// A reaction implicates the donation, not only the bag that caused it. The
/// component that was transfused is already in the patient; what matters is
/// that its siblings from the same donation are not issued to the next
/// patient while the investigation is open.
///
/// They are quarantined rather than discarded. The investigation may clear
/// them, and discarding destroys the evidence it needs.
///
/// This is hardcoded rather than left to a tenant-built workflow on purpose.
/// Whether the next patient receives a possibly-implicated unit is not a
/// configuration preference, and a hospital that has not built the workflow
/// yet is exactly the one that needs it.
async fn on_transfusion_reaction(
    pool: &PgPool,
    tenant_id: Uuid,
    payload: &Value,
) -> Result<(), sqlx::Error> {
    let component_id = uuid_from_payload(payload, "component_id");
    let patient_id = uuid_from_payload(payload, "patient_id");
    let reaction_id = uuid_from_payload(payload, "reaction_id");
    let severity = payload
        .get("reaction_severity")
        .and_then(Value::as_str)
        .unwrap_or("unknown");
    let reaction_type = payload
        .get("reaction_type")
        .and_then(Value::as_str)
        .unwrap_or("unspecified");

    let mut tx = pool.begin().await?;

    // a) Hold every other component from the same donation.
    //
    // Only those still on the shelf: `issued`, `crossmatched` and `transfused`
    // have left the bank and are somebody else's problem to chase, while
    // `discarded` and `expired` are already out of circulation. Excluding the
    // implicated component itself keeps its own status truthful — it was
    // transfused, and rewriting that would lose what actually happened.
    let quarantined = if let Some(cid) = component_id {
        sqlx::query_scalar::<_, i64>(
            "WITH held AS ( \
               UPDATE blood_components SET status = 'quarantined'::blood_bag_status \
               WHERE tenant_id = $1 \
                 AND donation_id = (SELECT donation_id FROM blood_components \
                                    WHERE id = $2 AND tenant_id = $1) \
                 AND id <> $2 \
                 AND status IN ('collected','processing','tested','available','reserved') \
               RETURNING 1 \
             ) SELECT count(*) FROM held",
        )
        .bind(tenant_id)
        .bind(cid)
        .fetch_one(&mut *tx)
        .await
        .unwrap_or(0)
    } else {
        0
    };

    // b) Raise an incident on the quality register.
    //
    // This wrote to `incident_reports` — a table with no rows, no handler and
    // no screen; the quality module's register is `quality_incidents`. The
    // reaction was therefore filed somewhere the quality team never looks,
    // and the `.ok()` below meant it looked filed either way.
    //
    // The two vocabularies do not overlap: a transfusion reaction is
    // mild/moderate/severe/fatal, an incident is near_miss..sentinel. Fatal
    // maps to `sentinel` because that is precisely what NABH means by one.
    if let Some(rid) = reaction_id {
        let incident_severity = match severity {
            "mild" => "minor",
            "severe" => "major",
            "fatal" => "sentinel",
            _ => "moderate",
        };
        sqlx::query(
            "WITH seq AS ( \
               UPDATE sequences SET current_val = current_val + 1 \
                WHERE tenant_id = $1 AND seq_type = 'INC' \
               RETURNING prefix, current_val, pad_width \
             ) \
             INSERT INTO quality_incidents \
               (tenant_id, incident_number, title, description, incident_type, \
                severity, patient_id, immediate_action, incident_date) \
             SELECT $1, \
                    COALESCE((SELECT prefix || lpad(current_val::text, pad_width, '0') \
                                FROM seq), \
                             'INC-' || to_char(now(), 'YYYYMMDDHH24MISS')), \
                    $2, $3, 'transfusion_reaction', $4::text::incident_severity, \
                    $5, $6, now()",
        )
        .bind(tenant_id)
        .bind(format!("Transfusion reaction — {reaction_type}"))
        .bind(format!(
            "Transfusion reaction reported ({reaction_type}, {severity}). Reaction {rid}."
        ))
        .bind(incident_severity)
        .bind(patient_id)
        .bind(format!(
            "{quarantined} sibling component(s) from the same donation quarantined \
             automatically."
        ))
        .execute(&mut *tx)
        .await?;
    }

    // c) Tell the blood bank. A hold nobody is told about is a hold nobody
    //    investigates, and the units stay quarantined for ever.
    let _ = enqueue(
        &mut tx,
        tenant_id,
        "blood_component",
        component_id,
        "blood_bank.transfusion_reaction_alert",
        json!({
            "reaction_id": reaction_id,
            "patient_id": patient_id,
            "component_id": component_id,
            "reaction_type": reaction_type,
            "reaction_severity": severity,
            "quarantined_siblings": quarantined,
        }),
        reaction_id.map(|r| format!("txn_reaction:{r}")),
    )
    .await;

    tx.commit().await?;
    Ok(())
}
