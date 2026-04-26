import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var weightInt: Int = 70
    @State private var heightInt: Int = 175
    @State private var gender = "Не указан"

    // Состояние ошибки имени
    @State private var nameError = false
    @State private var nameFieldShake = false
    @FocusState private var nameFieldFocused: Bool

    private let totalSteps = 3
    private let genders = ["Мужской", "Женский", "Не указан"]

    var body: some View {
        ZStack {
            Color(white: 0.12).ignoresSafeArea()
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("Шаг \(step + 1) из \(totalSteps)")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.1))
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.8))
                            .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps), height: 3)
                            .animation(.spring(response: 0.4), value: step)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Content
                TabView(selection: $step) {
                    nameStep.tag(0)
                    bodyStep.tag(1)
                    genderStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5), value: step)
                .scrollDisabled(true)

                // Next button
                Button {
                    nextStep()
                } label: {
                    Text(step == totalSteps - 1 ? "Начать" : "Далее")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.34, green: 0.84, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .dismissKeyboardOnTap()
        .onAppear { prefillFromAuth() }
    }

    // MARK: - Steps

    var nameStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Как тебя зовут?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Это будет отображаться в профиле")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 12) {
                // Поле имени с подсветкой ошибки
                OnboardingField(
                    placeholder: "Имя *",
                    text: $firstName,
                    hasError: nameError,
                    isFocused: $nameFieldFocused
                )
                .offset(x: nameFieldShake ? -8 : 0)
                .onChange(of: firstName) { _, _ in
                    if nameError && !firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                        withAnimation(.spring(response: 0.3)) { nameError = false }
                    }
                }

                // Подсказка об ошибке
                if nameError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                        Text("Пожалуйста, введи имя")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 1.0, green: 0.4, blue: 0.4))
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                OnboardingField(placeholder: "Фамилия", text: $lastName)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    var bodyStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Параметры тела")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Используются для анализа здоровья")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 20) {
                // Weight + Height в одной карточке с ruler-picker'ом — такой же,
                // как в настройках профиля (ProfileView → physicalSection).
                VStack(spacing: 0) {
                    OnbRulerPickerRow(
                        label: "Рост",
                        value: $heightInt,
                        range: 100...250,
                        unit: "см",
                        fg: .white,
                        accent: Color(red: 0.0, green: 0.48, blue: 1.0),
                        icon: "ruler.fill",
                        iconColor: Color(red: 0.20, green: 0.78, blue: 0.35)
                    )
                    Divider().background(.white.opacity(0.08)).padding(.leading, 16)
                    OnbRulerPickerRow(
                        label: "Вес",
                        value: $weightInt,
                        range: 30...300,
                        unit: "кг",
                        fg: .white,
                        accent: Color(red: 0.0, green: 0.48, blue: 1.0),
                        icon: "scalemass.fill",
                        iconColor: Color(red: 1.0, green: 0.42, blue: 0.62)
                    )
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))

                // Birth date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Дата рождения")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                    DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .colorScheme(.dark)
                        .labelsHidden()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    var genderStep: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ещё немного")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Помогает точнее анализировать данные")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.5))
            }

            VStack(spacing: 10) {
                ForEach(genders, id: \.self) { g in
                    Button {
                        withAnimation(.spring(response: 0.3)) { gender = g }
                    } label: {
                        HStack {
                            Text(g)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            if gender == g {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20))
                            }
                        }
                        .padding(18)
                        .background(
                            gender == g
                            ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.16, green: 0.53, blue: 1.0).opacity(0.55), Color(red: 0.14, green: 0.82, blue: 0.88).opacity(0.38)], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Material.ultraThinMaterial),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(gender == g ? .white.opacity(0.3) : .white.opacity(0.1), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    // MARK: - Logic

    func nextStep() {
        // Всегда проверяем имя — на любом шаге
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            triggerNameError()
            return
        }

        if step < totalSteps - 1 {
            withAnimation(.spring(response: 0.4)) { step += 1 }
        } else {
            appState.completeOnboarding(
                firstName: firstName,
                lastName: lastName,
                birthDate: birthDate,
                weightKg: Double(weightInt),
                heightCm: Double(heightInt),
                gender: gender
            )
        }
    }

    private func triggerNameError() {
        // 1. Возвращаем на шаг с именем
        withAnimation(.spring(response: 0.4)) { step = 0 }

        // 2. Небольшая задержка, потом показываем ошибку и фокусируем поле
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.3)) { nameError = true }
            nameFieldFocused = true

            // 3. Shake-анимация поля
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 10)) {
                nameFieldShake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation { nameFieldShake = false }
            }
        }
    }

    private func prefillFromAuth() {
        guard firstName.isEmpty, lastName.isEmpty, let fullName = appState.authUser?.fullName else { return }
        let parts = fullName.split(separator: " ")
        if let first = parts.first { firstName = String(first) }
        if parts.count > 1 { lastName = parts.dropFirst().joined(separator: " ") }
    }
}

// MARK: - Onboarding Field

struct OnboardingField: View {
    let placeholder: String
    @Binding var text: String
    var hasError: Bool = false
    var isFocused: FocusState<Bool>.Binding? = nil

    var body: some View {
        Group {
            if let isFocused {
                TextField(placeholder, text: $text)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .focused(isFocused)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                hasError
                                    ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.8)
                                    : .white.opacity(0.15),
                                lineWidth: hasError ? 1.5 : 0.5
                            )
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                    )
            }
        }
        // Красная подсветка фона при ошибке
        .background(
            Capsule()
                .fill(hasError ? Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.08) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.2), value: hasError)
    }
}

// MARK: - Ruler Picker (Onboarding copy of ProfileView's RulerPickerRow)
//
// Визуально и поведенчески один в один с `RulerPickerRow` из ProfileView.swift
// (там структуры `private`, поэтому здесь — локальная копия с префиксом `Onb`).
// Свободный drag + snap к тику + momentum через `predictedEndTranslation`,
// rubber-banding за границами диапазона.

private struct OnbRulerPickerRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    let fg: Color
    let accent: Color
    var icon: String? = nil
    var iconColor: Color = .blue

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6.24)
                            .fill(iconColor)
                            .frame(width: 24, height: 24)
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(fg)
                Spacer(minLength: 4)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(value)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(fg)
                    Text(unit)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(fg.opacity(0.45))
                }
                .animation(.spring(response: 0.28, dampingFraction: 0.85), value: value)
            }
            OnbRuler(value: $value, range: range, fg: fg, accent: accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct OnbRuler: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let fg: Color
    let accent: Color

    private let tickSpacing: CGFloat = 10
    private let tickH: CGFloat = 10
    private let tickMidH: CGFloat = 16
    private let tickMajorH: CGFloat = 22

    @State private var offsetX: CGFloat = 0
    @State private var dragStart: CGFloat? = nil
    @State private var lastHaptic: Int = .min

    private var count: Int { range.upperBound - range.lowerBound + 1 }
    private var minOffset: CGFloat { -CGFloat(count - 1) * tickSpacing }
    private let maxOffset: CGFloat = 0

    private func offsetFor(_ v: Int) -> CGFloat {
        -CGFloat(v - range.lowerBound) * tickSpacing
    }
    private func valueAt(_ offset: CGFloat) -> Int {
        let idx = Int((-offset / tickSpacing).rounded())
        let clamped = max(0, min(count - 1, idx))
        return range.lowerBound + clamped
    }
    private func rubberBand(_ x: CGFloat) -> CGFloat {
        if x > maxOffset { return maxOffset + (x - maxOffset) * 0.35 }
        if x < minOffset { return minOffset + (x - minOffset) * 0.35 }
        return x
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            ZStack {
                HStack(spacing: 0) {
                    ForEach(range, id: \.self) { i in
                        tickView(for: i)
                            .frame(width: tickSpacing, alignment: .center)
                    }
                }
                .padding(.vertical, 8)
                .offset(x: centerX + offsetX, y: 0)
                .frame(width: geo.size.width, height: 56, alignment: .leading)

                VStack(spacing: 2) {
                    OnbTriangle()
                        .fill(accent)
                        .frame(width: 8, height: 6)
                    Rectangle()
                        .fill(accent)
                        .frame(width: 2, height: 26)
                }
                .shadow(color: accent.opacity(0.4), radius: 4, y: 1)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.00),
                        .init(color: .black,            location: 0.12),
                        .init(color: .black,            location: 0.88),
                        .init(color: .black.opacity(0), location: 1.00)
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        if dragStart == nil { dragStart = offsetX }
                        let raw = (dragStart ?? 0) + g.translation.width
                        offsetX = rubberBand(raw)
                        let v = valueAt(offsetX)
                        if v != lastHaptic {
                            UISelectionFeedbackGenerator().selectionChanged()
                            lastHaptic = v
                        }
                        if v != value { value = v }
                    }
                    .onEnded { g in
                        let start = dragStart ?? offsetX
                        let predictedRaw = start + g.predictedEndTranslation.width
                        let targetValue = valueAt(predictedRaw)
                        let target = offsetFor(targetValue)
                        dragStart = nil
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            offsetX = target
                        }
                        if targetValue != value {
                            value = targetValue
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                        lastHaptic = targetValue
                    }
            )
        }
        .frame(height: 56)
        .onChange(of: value, initial: true) { _, new in
            guard dragStart == nil else { return }
            let target = offsetFor(new)
            if abs(offsetX - target) > 0.5 {
                offsetX = target
            }
            lastHaptic = new
        }
    }

    @ViewBuilder
    private func tickView(for i: Int) -> some View {
        let isMajor = i % 10 == 0
        let isMid   = i % 5 == 0 && !isMajor
        let h: CGFloat = isMajor ? tickMajorH : (isMid ? tickMidH : tickH)
        let opacity: Double = isMajor ? 0.8 : (isMid ? 0.5 : 0.28)

        VStack(spacing: 3) {
            Rectangle()
                .fill(fg.opacity(opacity))
                .frame(width: 1, height: h)
            if isMajor {
                Text("\(i)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(fg.opacity(0.5))
                    .fixedSize()
            } else {
                Color.clear.frame(height: 10)
            }
        }
    }
}

private struct OnbTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}
