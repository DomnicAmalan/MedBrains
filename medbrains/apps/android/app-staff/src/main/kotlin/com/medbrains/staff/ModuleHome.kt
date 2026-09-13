package com.medbrains.staff

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountCircle
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.adaptive.navigationsuite.NavigationSuiteScaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.medbrains.kit.AppModule
import com.medbrains.kit.AuthStore
import com.medbrains.kit.TenantIdentity
import com.medbrains.kit.accessibleTo

/**
 * One destination per permitted module, in registry order, so each role
 * lands on its own work. NavigationSuiteScaffold picks a bar, rail or drawer
 * from the window size class, so foldables and tablets need no code here.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModuleHome(auth: AuthStore, identity: TenantIdentity, modules: List<AppModule>, initialModule: String?) {
    val visible = remember(identity) { modules.accessibleTo(identity) }
    if (visible.isEmpty()) {
        EmptyRole(auth)
        return
    }
    var selected by remember { mutableStateOf(visible.firstOrNull { it.id == initialModule } ?: visible.first()) }
    var menuOpen by remember { mutableStateOf(false) }

    NavigationSuiteScaffold(
        navigationSuiteItems = {
            visible.forEach { module ->
                item(
                    selected = module.id == selected.id,
                    onClick = { selected = module },
                    icon = { Icon(module.icon, contentDescription = null) },
                    label = { Text(module.displayName) },
                    modifier = Modifier.testTag("module-${module.id}"),
                )
            }
        },
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text(selected.displayName) },
                    actions = {
                        IconButton(onClick = { menuOpen = true }) {
                            Icon(Icons.Filled.AccountCircle, contentDescription = "Account")
                        }
                        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                            DropdownMenuItem(text = { Text(identity.fullName) }, onClick = {}, enabled = false)
                            DropdownMenuItem(text = { Text("Sign out") }, onClick = { menuOpen = false; auth.signOut() })
                        }
                    },
                )
            },
        ) { padding ->
            Column(Modifier.padding(padding)) { selected.home() }
        }
    }
}

@Composable
private fun EmptyRole(auth: AuthStore) {
    Column(Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Nothing assigned to you here", style = MaterialTheme.typography.titleLarge)
        Text("Your role has no module on this app. Ask an administrator, or sign in on the right app.")
        androidx.compose.material3.TextButton(onClick = { auth.signOut() }) { Text("Sign out") }
    }
}

/** A module home not yet converted: says so, and shows what the role will get. */
@Composable
fun PlaceholderModuleHome(module: AppModule, phase: Int) {
    LazyColumn(Modifier.fillMaxSize()) {
        item {
            ListItem(
                headlineContent = { Text("Converting in phase $phase") },
                supportingContent = { Text("${module.displayName} keeps running on the current app until this screen lands natively.") },
            )
        }
        item { Text("Surfaces", style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(16.dp, 8.dp)) }
        items(module.appCodes) { ListItem(headlineContent = { Text(it, fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace) }) }
        item { Text("Requires", style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(16.dp, 8.dp)) }
        items(module.requiredPermissions) { ListItem(headlineContent = { Text(it, fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace) }) }
    }
}
