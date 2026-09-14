package com.medbrains.staff

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Apartment
import androidx.compose.material.icons.filled.Bloodtype
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CleaningServices
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Medication
import androidx.compose.material.icons.filled.MonitorHeart
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.SupportAgent
import androidx.compose.material.icons.filled.Sync
import androidx.compose.ui.graphics.vector.ImageVector
import com.medbrains.kit.AppModule
import com.medbrains.staff.nurse.NurseModule

/**
 * The staff registry, in the order apps/mobile-staff/src/modules/index.ts
 * keeps it. Order is not cosmetic: the shell opens on the first permitted
 * module, so this list decides where each role lands. Desk and clinical
 * modules first, cross-cutting ones after.
 */
object StaffModules {
    val registry: List<AppModule> = listOf(
        module("doctor", "Doctor", Icons.Filled.MonitorHeart, listOf("opd.visit.update"), listOf("Mobile-Doctor"), 3),
        AppModule(id = "nurse", displayName = "Nurse", requiredPermissions = listOf("nurse.dashboard.view"), appCodes = listOf("Mobile-Nurse"), icon = Icons.Filled.LocalHospital) { NurseModule() },
        module("reception", "Reception", Icons.Filled.SupportAgent, listOf("front_office.queue.list"), listOf("Desktop-Kiosk", "Desktop-Workstation", "Mobile-Admin", "Mobile-Security"), 5),
        module("pharmacy", "Pharmacy", Icons.Filled.Medication, listOf("pharmacy.prescriptions.list"), listOf("Mobile-Pharmacist"), 5),
        module("lab", "Lab", Icons.Filled.Science, listOf("lab.orders.list"), listOf("Mobile-LabTech", "Mobile-Phlebo"), 5),
        module("blood-bank", "Blood Bank", Icons.Filled.Bloodtype, listOf("blood_bank.inventory.list"), listOf("Mobile-LabTech", "Mobile-Nurse", "Mobile-Doctor"), 5),
        module("billing", "Billing", Icons.Filled.AccountBalanceWallet, listOf("billing.invoices.list"), listOf("Mobile-Admin", "Desktop-Workstation"), 5),
        module("bme", "BME", Icons.Filled.Build, listOf("bme.equipment.list"), listOf("Mobile-BME", "Desktop-DeviceBridge", "Mobile-Vendor"), 5),
        module("facilities", "Facilities", Icons.Filled.Apartment, listOf("facilities.work_orders.list"), listOf("Mobile-BME", "Mobile-Housekeeping", "TV-Wayfinding"), 5),
        module("housekeeping", "Housekeeping", Icons.Filled.CleaningServices, listOf("housekeeping.cleaning.list"), listOf("Mobile-Housekeeping", "TV-Ward"), 5),
        module("security", "Security", Icons.Filled.Security, listOf("security.incidents.list"), listOf("Mobile-Security", "TV-Emergency"), 5),
        module("hr", "HR", Icons.Filled.Groups, listOf("hr.attendance.list"), listOf("Mobile-Admin"), 5),
        module("device-sync", "Device sync", Icons.Filled.Sync, emptyList(), listOf("Mobile-Admin"), 6),
    )

    private fun module(id: String, name: String, icon: ImageVector, all: List<String>, apps: List<String>, phase: Int): AppModule {
        lateinit var self: AppModule
        self = AppModule(id = id, displayName = name, requiredPermissions = all, appCodes = apps, icon = icon) {
            PlaceholderModuleHome(self, phase)
        }
        return self
    }
}
