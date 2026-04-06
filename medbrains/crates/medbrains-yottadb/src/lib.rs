//! # medbrains-yottadb
//!
//! `YottaDB` REST client for hierarchical clinical data storage.
//! This crate is **Phase 2** — the server starts without it and
//! the health check reports `YottaDB` as "deferred".
//!
//! ## Planned Usage
//!
//! - `^CONFIG(tenantId,layer,module,key)` — 7-layer configuration tree
//! - `^SEQUENCE(tenantId,type)` — atomic counters (UHID, invoice numbers)
//! - `^BEDSTATE(tenantId,locationId)` — real-time bed occupancy state
//!
//! ## Modules
//!
//! - [`client`] — HTTP client for the `YottaDB` REST API
//! - [`globals`] — Global variable path builders

pub mod client;
pub mod globals;
