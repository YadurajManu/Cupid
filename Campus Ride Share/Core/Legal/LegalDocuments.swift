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
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedSection: Int? = nil
    @State private var appearAnimation = false
    
    let title: String
    let content: String
    
    // Parse sections for table of contents
    private var sections: [String] {
        let pattern = #"## \d+\.\s+(.*?)$"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        return matches.map { match in
            let range = match.range(at: 1)
            return nsString.substring(with: range)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header with aesthetic styling
                        VStack(alignment: .leading, spacing: 16) {
                            Text(title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            // Last updated info
                            Text("Last Updated: \(Date().formatted(.dateTime.month().day().year()))")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.bottom, 10)
                            
                            // Table of contents
                            if !sections.isEmpty {
                                Text("SECTIONS")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.gray)
                                    .tracking(1.5)
                                    .padding(.top, 10)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                                        Button(action: {
                                            withAnimation {
                                                selectedSection = index
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    selectedSection = nil
                                                }
                                            }
                                        }) {
                                            HStack {
                                                Text("\(index + 1).")
                                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .frame(width: 30, alignment: .leading)
                                                
                                                Text(section)
                                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedSection == index ? 
                                                          Color.white.opacity(0.1) : Color.clear)
                                            )
                                            .animation(.easeInOut(duration: 0.2), value: selectedSection)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                        
                        // Divider with gradient
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white.opacity(0.2), .white.opacity(0)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        
                        // Document content with styled markdown
                        StyledMarkdownText(content: content)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 50)
                    }
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                }
                .coordinateSpace(name: "scroll")
                
                // Bottom gradient for fading effect
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 50)
                }
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appearAnimation = true
            }
        }
    }
}

// Styled Markdown component
struct StyledMarkdownText: View {
    let content: String
    
    var body: some View {
        ParsedMarkdownText(markdown: content)
    }
}

// Custom Markdown Parser View
struct ParsedMarkdownText: View {
    let markdown: String
    
    var body: some View {
        let parsedContent = parseMarkdown(markdown)
        
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(parsedContent.indices, id: \.self) { index in
                let component = parsedContent[index]
                
                switch component.type {
                case .heading1:
                    Text(component.text)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 16)
                        .padding(.top, 24)
                
                case .heading2:
                    Text(component.text)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                        .padding(.top, 24)
                    
                    // Add subtle line under section headings
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50, height: 2)
                        .padding(.bottom, 16)
                
                case .paragraph:
                    Text(component.text)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(6)
                        .padding(.bottom, 16)
                
                case .bulletPoint:
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 5, height: 5)
                            .padding(.top, 8)
                        
                        Text(component.text)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(5)
                    }
                    .padding(.bottom, 8)
                
                case .bold:
                    Text(component.text)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 16)
                }
            }
        }
    }
    
    // Simple markdown parser that handles our specific format
    private func parseMarkdown(_ markdown: String) -> [MarkdownComponent] {
        var components: [MarkdownComponent] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        var currentParagraph = ""
        
        for line in lines {
            if line.hasPrefix("# ") {
                // Heading 1
                let headingText = String(line.dropFirst(2))
                components.append(MarkdownComponent(type: .heading1, text: headingText))
            } else if line.hasPrefix("## ") {
                // Heading 2
                let headingText = String(line.dropFirst(3))
                components.append(MarkdownComponent(type: .heading2, text: headingText))
            } else if line.hasPrefix("- ") {
                // Bullet point
                let bulletText = String(line.dropFirst(2))
                components.append(MarkdownComponent(type: .bulletPoint, text: bulletText))
            } else if line.hasPrefix("**") && line.hasSuffix("**") {
                // Bold text
                let boldText = String(line.dropFirst(2).dropLast(2))
                components.append(MarkdownComponent(type: .bold, text: boldText))
            } else if !line.isEmpty {
                // Regular paragraph
                components.append(MarkdownComponent(type: .paragraph, text: line))
            }
        }
        
        return components
    }
    
    // Markdown component types
    struct MarkdownComponent {
        enum ComponentType {
            case heading1, heading2, paragraph, bulletPoint, bold
        }
        
        let type: ComponentType
        let text: String
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
