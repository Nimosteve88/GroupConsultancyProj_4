//
//  ChatView.swift
//  type2DProj
//
//  Created by Nimo, Steve on 05/06/2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel: ChatViewModel
    @Namespace private var bottomID

    init() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        _viewModel = StateObject(wrappedValue: ChatViewModel(uid: uid))
    }

    var body: some View {
        VStack(spacing: 0) {
            // If there are no messages and the Copilot is not currently typing,
            // show a placeholder with logo + description:
            if viewModel.messages.isEmpty && !viewModel.isSending {
                Spacer()

                VStack(spacing: 20) {
                    // Replace "CopilotLogo" with your actual asset name
                    Image("CopilotLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .opacity(0.8)

                    Text("Welcome to Copilot!\n\nStart a conversation by typing below.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
            else {
                // MARK: – Chat bubbles + typing indicator
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { msg in
                                messageRow(for: msg)
                                    .id(msg.id)
                                    .padding(.horizontal, 12)
                            }

                            if viewModel.isSending {
                                typingIndicatorRow()
                                    .padding(.horizontal, 12)
                            }

                            // Invisible anchor at the bottom
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            scrollProxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isSending) { _ in
                        if viewModel.isSending {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    scrollProxy.scrollTo(bottomID, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }

            Divider()

            // MARK: – Input bar
            HStack(spacing: 8) {
                TextField(
                    "Type a message…",
                    text: $viewModel.draftText,
                    axis: .vertical
                )
                .lineLimit(1...5)
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)

                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(viewModel.isSending ? .gray : .blue)
                }
                .disabled(
                    viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isSending
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground).ignoresSafeArea(edges: .bottom))
        }
        .navigationBarTitle("Copilot", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.startNewChat()
                } label: {
                    Image(systemName: "plus.bubble")
                        .font(.system(size: 20, weight: .semibold))
                }
                .disabled(viewModel.isSending)
                .accessibilityLabel("New Chat")
            }
        }
    }

    // MARK: – Individual message bubble
    @ViewBuilder
    private func messageRow(for msg: ChatMessage) -> some View {
        if msg.sender == .user {
            HStack {
                Spacer()
                Text(msg.text)
                    .padding(12)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            }
        } else {
            HStack {
                Text(msg.text)
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                Spacer()
            }
        }
    }

    // MARK: – Typing indicator row
    @ViewBuilder
    private func typingIndicatorRow() -> some View {
        HStack {
            TypingIndicator()
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                .frame(maxWidth: UIScreen.main.bounds.width * 0.3, alignment: .leading)
            Spacer()
        }
    }
}

// MARK: – TypingIndicator View (three pulsing dots)
struct TypingIndicator: View {
    @State private var animate = false

    private let dotCount = 3
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 6

    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .frame(width: dotSize, height: dotSize)
                    .opacity(opacity(for: index))
                    .scaleEffect(scale(for: index))
            }
        }
        .frame(height: dotSize)
        .onAppear {
            withAnimation(
                Animation
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
            ) {
                animate.toggle()
            }
        }
    }

    private func opacity(for index: Int) -> Double {
        let delay = Double(index) * 0.2
        let base = animate ? 0.2 : 1.0
        return animate
            ? Double(1.0 - base) + base * Double((sin((Date().timeIntervalSinceReferenceDate + delay) * 3) + 1) / 2)
            : Double((sin((Date().timeIntervalSinceReferenceDate + delay) * 3) + 1) / 2)
    }

    private func scale(for index: Int) -> CGFloat {
        let delay = Double(index) * 0.2
        return animate
            ? 0.8 + 0.4 * CGFloat((sin((Date().timeIntervalSinceReferenceDate + delay) * 3) + 1) / 2)
            : 1.0
    }
}

#Preview {
    NavigationView {
        ChatView()
            .environmentObject(SessionStore())
    }
}


