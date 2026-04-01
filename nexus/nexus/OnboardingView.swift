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

    private let totalSteps = 3
    private let genders = ["Мужской", "Женский", "Не указан"]

    var body: some View {
        ZStack {
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
                            canProceed
                            ? LinearGradient(colors: [Color(red: 0.3, green: 0.4, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.1)], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                }
                .disabled(!canProceed)
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
                OnboardingField(placeholder: "Имя", text: $firstName)
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
                            ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.3, green: 0.4, blue: 1.0).opacity(0.4), Color(red: 0.5, green: 0.1, blue: 0.9).opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Material.ultraThinMaterial),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
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

    var canProceed: Bool {
        switch step {
        case 0: return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    func nextStep() {
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

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 17))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
            .edgeSheen(cornerRadius: 14)
    }
}
