import SwiftUI
import Foundation

// MARK: - HOME VIEW (Optimisée pour iPhone)
struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                homeBackground()
                homeContent()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 🌟 BACKGROUND : Radial Gradient & Fluid Animations
    private func homeBackground() -> some View {
        ZStack {
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
            
            FluidBackgroundView() // 🌊 Effets fluides maintenus
        }
    }

    // MARK: - 🎭 CONTENU PRINCIPAL : Titre, Sous-titre & Navigation
    private func homeContent() -> some View {
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
            
            // 🏷 "Carte" de Boutons (Dressing & Avatar)
            VStack(spacing: 15) {
                NavigationLink(destination: DressingItemListView()) {
                    AnimatedButtonLabel(
                        iconName: "bag.fill",
                        text: "Dressing"
                    )
                }
                
                NavigationLink(destination: AvatarView()) {
                    AnimatedButtonLabel(
                        iconName: "person.crop.circle",
                        text: "Avatar"
                    )
                }
            }
            .padding(20)
            .background(GlassBackgroundView()) // Effet de verre
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
}



// MARK: - FLUID BACKGROUND VIEW (BLOBS + PARTICULES)
// Remplace simplement ta struct FluidBackgroundView
// par cette nouvelle version plus "immersive".

// MARK: - HELPER FUNCTIONS

/// Returns a noise value (in the range roughly –1 to 1) by summing several sine waves whose amplitudes obey the Kolmogorov –5⁄3 scaling.
/// This function approximates a turbulent (fractal) noise spectrum.
func kolmogorovNoise(time t: Double, baseFrequency: Double, phase: Double, octaves: Int = 4) -> Double {
    var noise = 0.0
    var frequency = baseFrequency
    var amplitude = 1.0
    var totalAmplitude = 0.0
    for _ in 0..<octaves {
        noise += amplitude * sin(t * frequency + phase)
        totalAmplitude += amplitude
        amplitude *= pow(2, -5.0/3.0) // scale amplitude according to Kolmogorov’s law
        frequency *= 2
    }
    return noise / totalAmplitude
}

/// Linearly maps a value from one range to another.
func map(_ value: Double, from lower: Double, to upper: Double, newLower: Double, newUpper: Double) -> Double {
    return newLower + (value - lower) * (newUpper - newLower) / (upper - lower)
}

// MARK: - FLUID BACKGROUND VIEW

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
            SparkleField(count: 50, color: Color.white.opacity(0.15), maxSize: 4, speed: 8, rangeXY: 800)
            SparkleField(count: 30, color: Color.white.opacity(0.1), maxSize: 3, speed: 10, rangeXY: 800)
        }
        // Fixe la taille rapportée au parent = taille proposée (sinon les blobs
        // frame(width:600) inflatent le ZStack parent à 600pt et tout déborde)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

// MARK: - ENRICHED BLOB VIEW (with Kolmogorov turbulence)

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
    
    // Random phase offsets for independent noise channels
    let xPhase = Double.random(in: 0...1000)
    let yPhase = Double.random(in: 0...1000)
    let scalePhase = Double.random(in: 0...1000)
    let rotationPhase = Double.random(in: 0...1000)
    
    var body: some View {
        // TimelineView gives us a continuously updating time value
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // Set base frequency so that the first octave’s period is ~speed seconds.
            let baseFrequency = 2 * Double.pi / speed
            
            // Compute the noise values for each property using our Kolmogorov-inspired function.
            let noiseX = kolmogorovNoise(time: t, baseFrequency: baseFrequency, phase: xPhase)
            let noiseY = kolmogorovNoise(time: t, baseFrequency: baseFrequency, phase: yPhase)
            let noiseScale = kolmogorovNoise(time: t, baseFrequency: baseFrequency, phase: scalePhase)
            let noiseRotation = kolmogorovNoise(time: t, baseFrequency: baseFrequency, phase: rotationPhase)
            
            // Map the noise (≈–1 … 1) to the desired ranges.
            let xOffset = map(noiseX, from: -1, to: 1, newLower: Double(xRange.lowerBound), newUpper: Double(xRange.upperBound))
            let yOffset = map(noiseY, from: -1, to: 1, newLower: Double(yRange.lowerBound), newUpper: Double(yRange.upperBound))
            let scaleValue = map(noiseScale, from: -1, to: 1, newLower: Double(scaleRange.lowerBound), newUpper: Double(scaleRange.upperBound))
            let rotationValue = map(noiseRotation, from: -1, to: 1, newLower: rotationRange.lowerBound, newUpper: rotationRange.upperBound)
            
            // Hue rotation: progress linearly over time
            let hueAngle = (t.truncatingRemainder(dividingBy: hueShiftSpeed)) / hueShiftSpeed * 360
            
            // Opacity pulsing (if enabled)
            let opacityValue: Double = opacityPulse ? (0.75 + 0.25 * sin(t * baseFrequency)) : 1.0
            
            Circle()
                .fill(baseColor.opacity(opacityValue * 0.3))
                .hueRotation(Angle(degrees: hueAngle))
                .frame(width: size, height: size)
                .blur(radius: size / 4)
                .scaleEffect(CGFloat(scaleValue))
                .rotationEffect(.degrees(rotationValue))
                .offset(x: CGFloat(xOffset), y: CGFloat(yOffset))
        }
    }
}

// MARK: - SPARKLE FIELD (unchanged)

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
