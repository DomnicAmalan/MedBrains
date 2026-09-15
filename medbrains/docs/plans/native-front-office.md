# Front office on the native staff app — UI plan and scenarios

The first module built as a **full workflow** rather than a port of the outgoing
React Native screens (user direction 2026-09-15). Same code on iOS (SwiftUI) and
Android (Compose), in lockstep, with the rules in `medbrains-clinical-core`
(`registration.rs`) reached through `medbrains-edge-rn`.

## Who and when

A receptionist on a Monday morning registers forty walk-ins standing at the
desk, sends each to a clinic with a token, and calls the floor. The phone is
for the desk that is not at a desk: the camp gate, the corridor at 8 a.m., the
ER door. Everything is one-handed, short, and read back to the patient.

## Slices (each ends on the screen, both platforms, with its journeys)

| Slice | Screens | Server | Status |
|---|---|---|---|
| **A — registration to token** | Reception home · Register · Possible duplicate · Registered (UHID read-back) · Find patient · Patient · Start visit · Token issued · Queue board | `POST /patients/match`, `POST /patients`, `GET /patients?search`, `POST /opd/encounters`, `GET /tokens/worklist?module=opd`, `POST /tokens/call-next`, `GET /setup/departments`, `GET /setup/doctors` | this PR |
| B — appointments | Today's list · Check in (issues the token) · No-show · Book (doctor → date → slot) | `GET/POST /opd/appointments`, `PUT …/check-in`, `…/no-show`, `GET /opd/doctors/{id}/slots` | next |
| C — visitors and enquiries | Visitor desk (register, pass, in/out, revoke; active vs **overdue**) · Enquiry desk (log, resolve) | `/front-office/visitors`, `/passes`, `/visitor-logs`, `/enquiries` | after B |

## Found while building slice A — a policy question for the operator

**A receptionist can only list patients linked to them.** `GET /api/patients`
narrows a non-bypass caller to the patients ReBAC says they may view, and a
new registration links its registrar; nothing links a desk to a colleague's
walk-ins. So the front desk cannot find a returning patient another desk
registered — on this app or on the web page, which reads the same endpoint.
`POST /api/patients/match` is deliberately unfiltered, so the coherent path
today is Register → "Possible duplicate" → **Use this record** → Start visit,
and the journeys prove exactly that. The Find screen's empty state names the
scope. The fix, if wanted, is a relation in the authz grammar (a tenant-level
desk→patient viewer relation for the reception roles), not a wider gate here.
Also: `front_office_staff` holds no `patients.*` or `opd.*` code, so on this
app it sees the module with no action and is told so (`reception-no-actions`).

## Placement

Module `reception` in the staff registry, gated on `front_office.queue.list`
(both `receptionist` and `front_office_staff` hold it). Each home action is
gated on its own permission and hidden without it: Register `patients.create`,
Find `patients.list`, Queue board `opd.queue.list`. `front_office_staff` holds
no `patients.*`/`opd.*` code, so on this app it sees the module with no action
and is told so — a role gap in `roles.rs`, not a UI decision, recorded here
rather than papered over with a wider gate.

## Layout (phone-first)

- **Home**: page header · one stat tile "Waiting now" (worklist waiting count)
  · action rows in the order the desk works: Register, Find, Queue board.
- **Register** (one screen, no sections to scroll through — journey MJ-REC-006):
  Person: first name, last name, gender (segmented), phone, date of birth *or*
  age. Safety: medico-legal switch → MLC number; VIP switch. Optional: ABHA
  number. **Desk** (kept for the next walk-in): department, consultant,
  source (walk-in / referral → referred by). One primary action:
  **Check and register**.
- **Possible duplicate** (sheet over Register): the candidates from
  `/patients/match` — UHID, name, DOB, phone — each with **Use this record**;
  below, **Register as new anyway**. When the check could not run, the sheet
  is replaced by an inline warning "Duplicate check unavailable — nobody was
  compared" and the action reads **Register unverified**.
- **Registered**: the UHID in display type, name, DOB, phone — the two
  identifiers the desk reads back — then **Start visit** and **Next walk-in**
  (clears the person, keeps the desk).
- **Find**: search field (UHID, name, phone) · rows: name, `UHID · DOB · phone`,
  MLC/VIP tags · empty state in words · unavailable state named.
- **Patient**: identity card (the two identifiers), flags, last visit,
  outstanding balance · **Start OPD visit**.
- **Start visit**: department, consultant (prefilled from the desk), chief
  complaint (optional) · **Start visit and issue token**.
- **Token issued**: the token number in display type, "Tell them token N",
  patient name, department; announced to VoiceOver/TalkBack · **Queue board**,
  **Done**.
- **Queue board**: rows (token, name, status tag) · one **Call next (N waiting)**
  — the server picks under its lock; never a call per row.

## Components

iOS: `CarbonPageHeader`, `CarbonField`, `CarbonRow`, `CarbonTag`, `CarbonTile`,
`CarbonNotification`, `RemoteContentView`, `Eyebrow`, primary/tertiary/ghost
button styles. New primitive: **`CarbonPicker`** (menu picker with the Carbon
label/underline), used for department and consultant. Android: the same names
plus `CarbonActionRow`, `CarbonStatTile`; new **`CarbonPicker`** on an
`ExposedDropdownMenuBox`.

## States

Every list: loading · **unavailable** (named, with retry; the queue board says
"Do not read this as an empty floor") · empty (in words) · populated. Forms:
field refusal from the core rule before the tap; server refusal in words with
values kept; busy disables the one primary action.

## Data

Plain async calls through `ApiClient` (no cache layer on the phone); the
worklist polls every 5 s while the board is open. Desk context lives in the
module session for the run of the app, never in the secret store.

## Permissions

Registry gate `front_office.queue.list`. Actions: `patients.create`,
`patients.list`, `patients.view` (open a record), `opd.visit.create` (start a
visit), `opd.queue.list` (board), `opd.token.manage` (call next). Reads gate the
query: a screen without the permission is never reached, so it never fetches.

## Accessibility and safety

Every control labelled; targets ≥ 44 pt / 48 dp; the token and the UHID are
announced, not only shown; MLC and VIP are tags with words, never colour alone;
the duplicate sheet never hides that a match exists behind a scroll.

## Scenarios (the journeys, both platforms)

Given/When/Then, each read back from the server:

1. **Register a clean walk-in.** Given no patient with this phone, When the desk
   fills the person and taps Check and register, Then the match answers nobody,
   the record is created, and the UHID on screen equals the server's; the
   attributes record `duplicate_check: "none"`.
2. **A possible duplicate is confirmed, not silently created.** Given a patient
   seeded this run with the same name and phone, When the desk taps Check and
   register, Then the sheet lists that UHID; **Use this record** opens it and
   creates nothing; **Register as new anyway** creates a second record with
   `duplicate_check: "overridden"` and the matched UHID recorded.
3. **The check being down is not a clean check.** Given the match endpoint is
   unreachable (journey runs the form against an unreachable host for that
   call), Then the warning names it and the action reads Register unverified.
   (Proved on the core rule; the device journey proves the copy.)
4. **The second identifier is required.** Given no date of birth and no age,
   Then the field refuses before any request; with an age, the record carries
   `is_dob_estimated: true` and 1 January of the birth year.
5. **Medico-legal needs its number.** Given the switch on and no number, Then
   the field refuses; with a number, the record carries both.
6. **The desk survives the next walk-in.** Given a department chosen, When the
   desk taps Next walk-in, Then the department is still chosen and the name and
   phone are empty.
7. **Find by phone.** Given the seeded patient, When the desk searches the
   phone, Then the row shows the UHID; a nonsense search says so in words.
8. **Walk-in to token.** Given a registered patient, When the desk starts a
   visit in GEN-MEDICINE, Then the token on screen equals the server's queue
   `token_number` and the worklist holds the patient as waiting.
9. **Call next is the server's choice.** Given two waiting tokens, When the desk
   taps Call next, Then exactly one token is `called` on the server and the
   board shows it.
10. **Gates.** A `front_office_staff` identity sees the queue board and neither
    Register nor Find; a receptionist lands on Reception.
11. **Outage.** The board against an unreachable host names it and says not to
    read it as an empty floor.
