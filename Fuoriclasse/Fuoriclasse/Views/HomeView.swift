import SwiftUI

// MARK: - HOME VIEW (Optimisée pour iPhone)
struct HomeView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 🔹 1. Fond Radial (maintenu)
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 40/255, green: 10/255, blue: 90/255),
                        Color(red: 15/255, green: 5/255, blue: 40/255)
                    ]),
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                // 🔹 2. Fond Fluide (Blobs & Sparkles maintenus)
                FluidBackgroundView()
                
                // 🔹 3. Contenu Principal
                VStack(spacing: 25) {
                    Spacer().frame(height: 50) // Ajustement de l’espace en haut
                    
                    // 🎨 TITRE & SOUS-TITRE
                    VStack(spacing: 5) {
                        Text("Gioia")
                            .font(.custom("Futura-Bold", size: 42)) // Ajustement pour iPhone
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 2, y: 2)
                        
                        Text("Modern Fashion Experience")
                            .font(.custom("Futura", size: 20))
                            .foregroundColor(Color.white.opacity(0.95))
                    }
                    
                    // 🏷 "Carte" de Boutons
                    VStack(spacing: 15) {
                        NavigationLink(destination: DressingItemListView()) {
                            AnimatedButtonLabel(
                                iconName: "bag.fill",
                                text: "Dressing"
                            )
                        }
                        
                        NavigationLink(destination: AvatarView(navigationPath: $navigationPath)) {
                            AnimatedButtonLabel(
                                iconName: "person.crop.circle",
                                text: "Avatar"
                            )
                        }
                    }
                    .padding(20)
                    .background(GlassBackgroundView())
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - FLUID BACKGROUND VIEW (BLOBS + PARTICULES)
// Remplace simplement ta struct FluidBackgroundView
// par cette nouvelle version plus "immersive".

struct FluidBackgroundView: View {
    var body: some View {
        ZStack {
            // Blob 1 : Très grand, couvrant l’écran
            EnrichedBlobView(
                baseColor: Color(red: 1.0, green: 0.4, blue: 0.8),
                size: 600,
                speed: 10,
                scaleRange: 0.8...1.2,
                xRange: -600...600,
                yRange: -1000...1000,
                rotationRange: -30...30,
                hueShiftSpeed: 12,
                opacityPulse: true
            )
            
            // Blob 2
            EnrichedBlobView(
                baseColor: Color(red: 0.3, green: 0.7, blue: 1.0),
                size: 500,
                speed: 9,
                scaleRange: 0.7...1.3,
                xRange: -650...650,
                yRange: -900...900,
                rotationRange: -25...25,
                hueShiftSpeed: 14,
                opacityPulse: false
            )
            
            // Blob 3
            EnrichedBlobView(
                baseColor: Color(red: 0.8, green: 0.6, blue: 1.0),
                size: 550,
                speed: 11,
                scaleRange: 0.8...1.4,
                xRange: -600...600,
                yRange: -800...800,
                rotationRange: -40...40,
                hueShiftSpeed: 10,
                opacityPulse: true
            )
            
            // Blob 4
            EnrichedBlobView(
                baseColor: Color(red: 1.0, green: 0.8, blue: 0.4),
                size: 450,
                speed: 8,
                scaleRange: 0.8...1.3,
                xRange: -650...650,
                yRange: -900...900,
                rotationRange: -10...10,
                hueShiftSpeed: 16,
                opacityPulse: false
            )
            
            // Blob 5 (optionnel) : un 5e blob pour encore plus de densité
            EnrichedBlobView(
                baseColor: Color(red: 0.5, green: 1.0, blue: 0.7),
                size: 500,
                speed: 12,
                scaleRange: 0.8...1.2,
                xRange: -700...700,
                yRange: -900...900,
                rotationRange: -30...30,
                hueShiftSpeed: 13,
                opacityPulse: true
            )
            
            // Sparkles (discrètes, mais sur un large périmètre)
            SparkleField(count: 50, color: .white.opacity(0.15), maxSize: 4, speed: 8, rangeXY: 800)
            SparkleField(count: 30, color: .white.opacity(0.1), maxSize: 3, speed: 10, rangeXY: 800)
        }
    }
}

// MARK: - ENRICHED BLOB VIEW
struct EnrichedBlobView: View {
    let baseColor: Color
    let size: CGFloat
    let speed: Double
    
    let scaleRange: ClosedRange<CGFloat>
    let xRange: ClosedRange<CGFloat>
    let yRange: ClosedRange<CGFloat>
    let rotationRange: ClosedRange<Double>
    
    let hueShiftSpeed: Double
    let opacityPulse: Bool
    
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    @State private var hueAngle: Double = 0
    @State private var opacityValue: Double = 1.0
    
    var body: some View {
        Circle()
            .fill(baseColor.opacity(opacityValue * 0.3))
            .hueRotation(Angle(degrees: hueAngle))
            .frame(width: size, height: size)
            .blur(radius: size / 4)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                xOffset = random(in: xRange)
                yOffset = random(in: yRange)
                scale = random(in: scaleRange)
                rotation = random(in: rotationRange)
                
                withAnimation(Animation.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                    xOffset = random(in: xRange)
                    yOffset = random(in: yRange)
                    scale = random(in: scaleRange)
                    rotation = random(in: rotationRange)
                }
                
                withAnimation(Animation.linear(duration: hueShiftSpeed).repeatForever(autoreverses: false)) {
                    hueAngle = 360
                }
                
                if opacityPulse {
                    withAnimation(Animation.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                        opacityValue = 0.5
                    }
                }
            }
    }
    
    private func random(in range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat.random(in: range)
    }
    private func random(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}

// MARK: - SPARKLE FIELD
struct SparkleField: View {
    let count: Int
    let color: Color
    let maxSize: CGFloat
    let speed: Double
    let rangeXY: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { _ in
                SparkleView(color: color, maxSize: maxSize, speed: speed, rangeXY: rangeXY)
            }
        }
    }
}

struct SparkleView: View {
    let color: Color
    let maxSize: CGFloat
    let speed: Double
    let rangeXY: CGFloat
    
    @State private var position: CGPoint = .zero
    @State private var size: CGFloat = 1
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .opacity(opacity)
            .onAppear {
                randomize()
                withAnimation(Animation.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                    randomize()
                }
            }
            .offset(x: position.x, y: position.y)
    }
    
    private func randomize() {
        position = CGPoint(
            x: CGFloat.random(in: -rangeXY...rangeXY),
            y: CGFloat.random(in: -rangeXY...rangeXY)
        )
        size = CGFloat.random(in: 1...maxSize)
        opacity = Double.random(in: 0.1...0.6)
    }
}

// MARK: - EFFET DE VERRE
struct GlassBackgroundView: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.15)
                .blur(radius: 4)
            
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    Color.black.opacity(0.25),
                    lineWidth: 4
                )
                .blur(radius: 8)
                .offset(x: 2, y: 2)
                .mask(
                    RoundedRectangle(cornerRadius: 24)
                )
        }
    }
}

// MARK: - BOUTON ANIMÉ (Sans onLongPressGesture)
struct AnimatedButtonLabel: View {
    let iconName: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)
            
            Text(text)
                .font(.custom("Futura", size: 20))
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 4)
    }
}
