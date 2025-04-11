import SwiftUI

// Content for legal documents
struct LegalContent {
    // Terms of Service content
    static let termsOfService = """
# Terms of Service

**Last Updated: \(Date().formatted(.dateTime.month().day().year()))**

## 1. Acceptance of Terms

By accessing or using the Campus Ride Share app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.

## 2. Eligibility

You must be at least 18 years old to use Campus Ride Share. By using our service, you represent and warrant that you are at least 18 years of age.

## 3. User Accounts

- You are responsible for maintaining the confidentiality of your account credentials
- You agree to accept responsibility for all activities that occur under your account
- You must provide accurate, current, and complete information when creating an account

## 4. User Conduct

You agree not to:
- Use the service for any illegal purpose
- Harass, abuse, or harm another person
- Impersonate any person or entity
- Post false, misleading, or offensive content
- Attempt to circumvent any security features of the service

## 5. Content Guidelines

- You retain ownership of any content you submit to Campus Ride Share
- By posting content, you grant us a non-exclusive, worldwide, royalty-free license to use this content
- We reserve the right to remove content that violates these terms

## 6. Safety

- Campus Ride Share is provided "as is" without warranty of any kind
- We do not guarantee that connections made through our service will be safe
- Users are encouraged to exercise caution and good judgment when meeting others

## 7. Termination

We reserve the right to terminate or suspend your account at our sole discretion, without notice, for conduct that we believe violates these Terms of Service or is harmful to other users, us, or third parties.

## 8. Changes to Terms

We may modify these terms at any time. Your continued use of Campus Ride Share constitutes acceptance of the modified terms.

## 9. Contact Information

If you have any questions about these Terms, please contact us at yadurajsingham@gmail.com.
"""

    // Privacy Policy content
    static let privacyPolicy = """
# Privacy Policy

**Last Updated: \(Date().formatted(.dateTime.month().day().year()))**

## 1. Information We Collect

**Personal Information:**
- Name, email address, and age
- Profile information including photos, biography, and preferences
- Location data (when enabled)
- Voice recordings (when provided)

**Usage Information:**
- Interactions with the app
- Device information
- IP address and network data

## 2. How We Use Your Information

We use your information to:
- Create and manage your account
- Provide our core functionality of matching users
- Improve our services
- Ensure safety and security
- Communicate with you about our service

## 3. Information Sharing

We do not sell your personal information. We may share information:
- With other users as part of the core service
- With service providers that help us operate
- When required by law
- In the event of a merger or acquisition

## 4. Your Privacy Choices

You can:
- Access and update your personal information
- Control location sharing permissions
- Delete your account and associated data
- Opt-out of certain communications

## 5. Data Security

We implement reasonable security measures to protect your information. However, no method of transmission over the Internet is 100% secure.

## 6. Data Retention

We retain your information as long as your account is active or as needed to provide services. You may request deletion of your account at any time.

## 7. Children's Privacy

Campus Ride Share is not intended for users under 18 years of age. We do not knowingly collect information from children.

## 8. International Data Transfers

Your information may be transferred to and processed in countries other than your country of residence.

## 9. Changes to This Policy

We may update this Privacy Policy occasionally. We will notify you of any material changes through the app.

## 10. Contact Us

If you have questions about this Privacy Policy, please contact us at yadurajsingham@gmail.com.
"""
}

// View for displaying legal documents
struct LegalDocumentView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let content: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Markdown parsing for the content
                    Text(.init(content))
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.black)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Terms of Service View
struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentView(
            title: "Terms of Service",
            content: LegalContent.termsOfService
        )
    }
}

// Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentView(
            title: "Privacy Policy",
            content: LegalContent.privacyPolicy
        )
    }
}

// Preview provider
struct LegalDocuments_Previews: PreviewProvider {
    static var previews: some View {
        TermsOfServiceView()
        PrivacyPolicyView()
    }
} 
