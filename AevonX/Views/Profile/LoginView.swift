//
//  LoginView.swift
//  AevonX
//
//  Connected Login/Register view with AuthService
//

import SwiftUI
import AevonXCoreBridge
import AevonXCore

struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""

    
    var body: some View {
        VStack(spacing: AXSpacing.xxl) {
            Spacer()
            
            // Logo
            VStack(spacing: AXSpacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.axAccentBlue.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.axAccentBlue)
                }
                
                Text("AevonX")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.axTextPrimary)
                
                Text(isSignUp ? "Create your account" : "Sign in to your account")
                    .font(AXTypography.callout)
                    .foregroundColor(.axTextSecondary)
            }
            
            // Trial Status Banner
            if isSignUp {
                TrialStatusBanner(viewModel: viewModel)
            }
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.axError)
                    Text(errorMessage)
                        .font(AXTypography.caption)
                        .foregroundColor(.axError)
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axError.opacity(0.1))
                .cornerRadius(AXCornerRadius.md)
            }
            
            // Form
            VStack(spacing: AXSpacing.lg) {
                if isSignUp {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text("Full Name")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        
                        TextField("", text: $name)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                            .padding(AXSpacing.md)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.md)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Email")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    TextField("", text: $email)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: AXSpacing.sm) {
                    Text("Password")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    SecureField("", text: $password)
                        .font(AXTypography.body)
                        .foregroundColor(.axTextPrimary)
                        .padding(AXSpacing.md)
                        .background(Color.axSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                .stroke(Color.axBorder, lineWidth: 1)
                        )
                        .cornerRadius(AXCornerRadius.md)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                if isSignUp {
                    VStack(alignment: .leading, spacing: AXSpacing.sm) {
                        Text("Confirm Password")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                        
                        SecureField("", text: $passwordConfirmation)
                            .font(AXTypography.body)
                            .foregroundColor(.axTextPrimary)
                            .padding(AXSpacing.md)
                            .background(Color.axSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AXCornerRadius.md)
                                    .stroke(Color.axBorder, lineWidth: 1)
                            )
                            .cornerRadius(AXCornerRadius.md)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                }
                
                Button(action: {
                    Task {
                        if isSignUp {
                            await viewModel.register(
                                name: name,
                                email: email,
                                password: password,
                                passwordConfirmation: passwordConfirmation
                            )
                        } else {
                            await viewModel.login(email: email, password: password)
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .axBackground))
                            .frame(maxWidth: 300)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(AXTypography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.axBackground)
                            .frame(maxWidth: 300)
                            .padding(.vertical, AXSpacing.md)
                            .background(Color.axAccentBlue)
                            .cornerRadius(AXCornerRadius.md)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
                .padding(.top, AXSpacing.md)
                
                Button(action: {
                    isSignUp.toggle()
                    viewModel.errorMessage = nil
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(AXTypography.subheadline)
                        .foregroundColor(.axAccentBlue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(viewModel.isLoading)
            }
            .frame(maxWidth: 300)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.axBackground)
    }
}

// MARK: - Trial Status Banner

struct TrialStatusBanner: View {
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        Group {
            switch viewModel.trialStatus {
            case .eligible:
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.axSuccess)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Free Trial Available")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axSuccess)
                        
                        Text("Start your 14-day free trial today")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSuccess.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axSuccess.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)
                
            case .used:
                HStack(spacing: AXSpacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.axWarning)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trial Not Available")
                            .font(AXTypography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.axWarning)
                        
                        Text("This device has already been used for a trial")
                            .font(AXTypography.caption)
                            .foregroundColor(.axTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axWarning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AXCornerRadius.md)
                        .stroke(Color.axWarning.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(AXCornerRadius.md)
                
            case .unknown:
                HStack(spacing: AXSpacing.sm) {
                    ProgressView()
                        .scaleEffect(0.7)
                    
                    Text("Checking trial eligibility...")
                        .font(AXTypography.caption)
                        .foregroundColor(.axTextSecondary)
                    
                    Spacer()
                }
                .padding(.horizontal, AXSpacing.md)
                .padding(.vertical, AXSpacing.sm)
                .background(Color.axSurface)
                .cornerRadius(AXCornerRadius.md)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: 300)
    }
}

#Preview {
    LoginView()
        .background(Color.axBackground)
}
