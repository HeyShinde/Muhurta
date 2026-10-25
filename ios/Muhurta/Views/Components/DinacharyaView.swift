//
//  DinacharyaView.swift
//  Muhurta
//
//  Morning ritual checklist view with completion tracking and Pranayama modal sheet.
//

import SwiftUI

public struct DinacharyaView: View {
    @State private var steps = DinacharyaStep.standardRoutine
    @State private var showingBreathModal = false
    
    public init() {}
    
    private var completedCount: Int {
        steps.filter { $0.isCompleted }.count
    }
    
    private var progressFraction: Double {
        Double(completedCount) / Double(steps.count)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DINACHARYA")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.35))
                    
                    Text("The Morning Ritual Checklist")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(completedCount)/\(steps.count)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 5)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.78, blue: 0.35),
                                    Color(red: 0.35, green: 0.88, blue: 0.70)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressFraction, height: 5)
                        .animation(.spring(), value: progressFraction)
                }
            }
            .frame(height: 5)
            
            // Checklist Items
            VStack(spacing: 10) {
                ForEach($steps) { $step in
                    DinacharyaRow(step: $step) {
                        if step.id == "pranayama_dhyana" {
                            showingBreathModal = true
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color(red: 0.09, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .sheet(isPresented: $showingBreathModal) {
            PranayamaPacerView()
        }
    }
}

private struct DinacharyaRow: View {
    @Binding var step: DinacharyaStep
    let onOpenBreathModal: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    step.isCompleted.toggle()
                }
                let feedback = UIImpactFeedbackGenerator(style: .light)
                feedback.impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .stroke(step.isCompleted ? Color(red: 0.35, green: 0.88, blue: 0.70) : Color.white.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    
                    if step.isCompleted {
                        Circle()
                            .fill(Color(red: 0.35, green: 0.88, blue: 0.70))
                            .frame(width: 16, height: 16)
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.black)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Emoji & Text
            Text(step.emoji)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(step.titleSanskrit)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(step.isCompleted ? .secondary : .white)
                    .strikethrough(step.isCompleted, color: .secondary)
                
                Text(step.benefits)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if step.id == "pranayama_dhyana" {
                Button {
                    onOpenBreathModal()
                } label: {
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.77, blue: 0.35))
                        .padding(8)
                        .background(Color(red: 0.95, green: 0.77, blue: 0.35).opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
