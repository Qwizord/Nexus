import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 0
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var weightKg: Double = 70
    @State private var heightCm: Double = 175
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
                // Weight
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Вес")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(weightKg)) кг")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Slider(value: $weightKg, in: 40...200, step: 0.5)
                        .tint(.white)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))

                // Height
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Рост")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("\(Int(heightCm)) см")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Slider(value: $heightCm, in: 140...220, step: 0.5)
                        .tint(.white)
                }
                .padding(16)
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
                weightKg: weightKg,
                heightCm: heightCm,
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
