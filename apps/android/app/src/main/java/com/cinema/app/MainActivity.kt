package com.cinema.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val CinemaBackground = Color(0xFF090D0B)
private val CinemaSurface = Color(0xFF141D17)
private val CinemaGreen = Color(0xFFB7F28C)
private val CinemaMuted = Color(0xFF9DAAA0)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { CinemaApp() }
    }
}

@Composable
private fun CinemaApp() {
    val colors = darkColorScheme(
        primary = CinemaGreen,
        onPrimary = Color(0xFF102015),
        background = CinemaBackground,
        onBackground = Color(0xFFF4F5EF),
        surface = CinemaSurface,
        onSurface = Color(0xFFF4F5EF),
        secondary = Color(0xFFB4C8B6)
    )

    MaterialTheme(colorScheme = colors) {
        var selectedTab by remember { mutableStateOf(0) }

        Scaffold(
            containerColor = CinemaBackground,
            bottomBar = {
                NavigationBar(containerColor = CinemaSurface) {
                    NavigationBarItem(
                        selected = selectedTab == 0,
                        onClick = { selectedTab = 0 },
                        icon = { Text("⌂", fontSize = 18.sp) },
                        label = { Text("Discover") }
                    )
                    NavigationBarItem(
                        selected = selectedTab == 1,
                        onClick = { selectedTab = 1 },
                        icon = { Text("＋", fontSize = 18.sp) },
                        label = { Text("My list") }
                    )
                    NavigationBarItem(
                        selected = selectedTab == 2,
                        onClick = { selectedTab = 2 },
                        icon = { Text("◉", fontSize = 18.sp) },
                        label = { Text("Profile") }
                    )
                }
            }
        ) { innerPadding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .background(CinemaBackground)
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 22.dp, vertical = 24.dp),
                verticalArrangement = Arrangement.spacedBy(22.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text("CINEMA", color = CinemaGreen, fontSize = 12.sp, fontWeight = FontWeight.Bold, letterSpacing = 3.sp)
                        Text(
                            when (selectedTab) {
                                1 -> "Your library"
                                2 -> "Your profile"
                                else -> "Watch with confidence"
                            },
                            color = Color.White,
                            fontSize = 25.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Surface(shape = RoundedCornerShape(12.dp), color = CinemaSurface) {
                        Text("C", modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp), color = CinemaGreen, fontWeight = FontWeight.Bold)
                    }
                }

                if (selectedTab == 0) {
                    DiscoverContent()
                } else {
                    EmptySection(
                        title = if (selectedTab == 1) "Your list starts here" else "Profile is coming",
                        description = if (selectedTab == 1) {
                            "Save titles after the verified catalogue is connected. Your list will sync across your devices."
                        } else {
                            "Account sign-in and cross-device sync will be added after the privacy and security model is ready."
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun DiscoverContent() {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("DISCOVERY, WITH TRANSPARENCY", color = CinemaGreen, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.8.sp)
        Text(
            "Find your next watch. Know the source first.",
            color = Color.White,
            fontSize = 34.sp,
            lineHeight = 39.sp,
            fontWeight = FontWeight.Bold
        )
        Text(
            "Films, series, and animation in one place — with rights and regional availability checked before playback.",
            color = CinemaMuted,
            fontSize = 14.sp,
            lineHeight = 22.sp
        )

        Card(
            colors = CardDefaults.cardColors(containerColor = CinemaSurface),
            shape = RoundedCornerShape(18.dp)
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Surface(color = Color(0xFF233A28), shape = RoundedCornerShape(50)) {
                        Text("✓", color = CinemaGreen, modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp))
                    }
                    Text("RIGHTS-FIRST CATALOGUE", color = CinemaGreen, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp)
                }
                Text("No unverified streams.", color = Color.White, fontSize = 21.sp, fontWeight = FontWeight.Bold)
                Text(
                    "Cinema will only enable playback when an authorized source and its territory rules have been recorded.",
                    color = CinemaMuted,
                    fontSize = 13.sp,
                    lineHeight = 20.sp
                )
                Button(
                    onClick = { },
                    enabled = false,
                    colors = ButtonDefaults.buttonColors(
                        disabledContainerColor = Color(0xFF26352A),
                        disabledContentColor = CinemaMuted
                    )
                ) {
                    Text("Catalogue connection pending")
                }
            }
        }

        Text("BUILT AROUND YOUR EXPERIENCE", color = CinemaGreen, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.5.sp)
        FeatureCard("One library", "Watchlist, collections, and progress designed for Android and web.")
        FeatureCard("Clear availability", "Territory, subtitles, audio, and source status shown before you choose.")
        FeatureCard("Lightweight by default", "Lazy loading and careful memory use for everyday Android devices.")
    }
}

@Composable
private fun FeatureCard(title: String, description: String) {
    Card(
        colors = CardDefaults.cardColors(containerColor = CinemaSurface),
        shape = RoundedCornerShape(14.dp)
    ) {
        Column(modifier = Modifier.padding(17.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(title, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
            Text(description, color = CinemaMuted, fontSize = 12.sp, lineHeight = 18.sp)
        }
    }
}

@Composable
private fun EmptySection(title: String, description: String) {
    Card(
        colors = CardDefaults.cardColors(containerColor = CinemaSurface),
        shape = RoundedCornerShape(18.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth().padding(22.dp),
            horizontalAlignment = Alignment.Start,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(title, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text(description, color = CinemaMuted, fontSize = 14.sp, lineHeight = 22.sp)
        }
    }
}
