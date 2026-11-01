package com.cinema.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val Bg = Color(0xFF090E0B)
private val Panel = Color(0xFF141E17)
private val Green = Color(0xFFB9F28F)
private val Muted = Color(0xFFA2AEA4)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { CinemaApp() }
    }
}

@Composable
private fun CinemaApp() {
    MaterialTheme(colorScheme = darkColorScheme(primary = Green, onPrimary = Color(0xFF142017), background = Bg, onBackground = Color.White, surface = Panel, onSurface = Color.White)) {
        var tab by remember { mutableIntStateOf(0) }
        Scaffold(containerColor = Bg, bottomBar = {
            NavigationBar(containerColor = Panel) {
                listOf("Discover", "My list", "Profile").forEachIndexed { index, label ->
                    NavigationBarItem(selected = tab == index, onClick = { tab = index }, icon = { Text(listOf("⌂", "＋", "◉")[index]) }, label = { Text(label) })
                }
            }
        }) { padding ->
            Column(Modifier.fillMaxSize().background(Bg).padding(padding).verticalScroll(rememberScrollState()).padding(22.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                Text("C I N E M A", color = Green, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                Text(listOf("Watch with confidence", "Your library", "Your profile")[tab], fontSize = 27.sp, fontWeight = FontWeight.Bold, color = Color.White)
                when (tab) {
                    0 -> Discover()
                    1 -> EmptyPanel("Your list starts here", "Save titles after the verified catalogue is connected. Your list will sync across devices.")
                    else -> EmptyPanel("Profile is coming", "Account sign-in and cross-device sync will be added after the privacy and security model is ready.")
                }
            }
        }
    }
}

@Composable
private fun Discover() {
    Text("DISCOVERY, WITH TRANSPARENCY", color = Green, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.5.sp)
    Text("Find your next watch. Know the source first.", color = Color.White, fontSize = 34.sp, lineHeight = 39.sp, fontWeight = FontWeight.Bold)
    Text("Films, series, and animation in one place — with rights and regional availability checked before playback.", color = Muted, fontSize = 14.sp, lineHeight = 22.sp)
    EmptyPanel("✓  RIGHTS-FIRST CATALOGUE", "No unverified streams. Cinema will only enable playback when an authorized source and its territory rules have been recorded.")
    Text("BUILT AROUND YOUR EXPERIENCE", color = Green, fontSize = 10.sp, fontWeight = FontWeight.Bold)
    EmptyPanel("One library", "Watchlist, collections, and progress designed for Android and web.")
    EmptyPanel("Clear availability", "Territory, subtitles, audio, and source status shown before you choose.")
    EmptyPanel("Lightweight by default", "Lazy loading and careful memory use for everyday Android devices.")
}

@Composable
private fun EmptyPanel(title: String, description: String) {
    Card(colors = CardDefaults.cardColors(containerColor = Panel), shape = RoundedCornerShape(16.dp)) {
        Column(Modifier.fillMaxWidth().padding(19.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
            Text(title, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 18.sp)
            Text(description, color = Muted, fontSize = 13.sp, lineHeight = 20.sp)
        }
    }
}
