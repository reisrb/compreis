import SwiftUI

struct PerfilView: View {
    @ObservedObject private var auth = GoogleAuth.shared
    @State private var clientIdDraft = ""
    @State private var showClientIdField = false
    @State private var connecting = false

    var body: some View {
        NavigationStack {
            Form {
                googleSection
                setupSection
            }
            .navigationTitle("Perfil")
            .tint(AppTheme.accent)
        }
    }

    // MARK: - Sections

    private var googleSection: some View {
        Section {
            if auth.isConnected {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentSubtle)
                            .frame(width: 42, height: 42)
                            .overlay(Circle().strokeBorder(AppTheme.accentBorder, lineWidth: 0.75))
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(AppTheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Google conectado")
                            .font(.body.weight(.bold))
                        if let email = auth.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)

                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Label("Desconectar conta", systemImage: "arrow.right.square")
                }
            } else {
                if showClientIdField {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Client ID do Google Cloud")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("XXXXXX.apps.googleusercontent.com", text: $clientIdDraft)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.caption.monospaced())
                        if !clientIdDraft.isEmpty {
                            Button {
                                auth.clientId = clientIdDraft
                                showClientIdField = false
                            } label: {
                                Text("Salvar Client ID")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else if !auth.clientId.isEmpty {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(auth.clientId)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Alterar") {
                            clientIdDraft = auth.clientId
                            showClientIdField = true
                        }
                        .font(.caption)
                    }
                }

                Button {
                    if auth.clientId.isEmpty {
                        clientIdDraft = ""
                        showClientIdField = true
                    } else {
                        connecting = true
                        Task {
                            await auth.signIn()
                            connecting = false
                        }
                    }
                } label: {
                    HStack {
                        if connecting {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }
                        Text(auth.clientId.isEmpty ? "Configurar Client ID" : "Conectar Google")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                .disabled(connecting)

                if let erro = auth.errorMessage {
                    Text(erro)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } header: { RockSectionHeader(title: "Google Sheets") }
         footer: {
            if !auth.isConnected {
                Text("Ao finalizar uma compra, os dados são salvos automaticamente numa planilha na sua conta Google.")
            }
        }
    }

    private var setupSection: some View {
        Section {
            Link(destination: URL(string: "https://console.cloud.google.com")!) {
                Label("Abrir Google Cloud Console", systemImage: "arrow.up.right.square")
                    .foregroundStyle(AppTheme.accent)
            }

            DisclosureGroup("Como configurar") {
                VStack(alignment: .leading, spacing: 8) {
                    passo(n: 1, texto: "Acesse console.cloud.google.com")
                    passo(n: 2, texto: "Crie um projeto (ex: \"Compreis\")")
                    passo(n: 3, texto: "Ative as APIs: Google Sheets e Google Drive")
                    passo(n: 4, texto: "Credenciais → Criar → ID do cliente OAuth → iOS")
                    passo(n: 5, texto: "Bundle ID: com.rafaelreis.compreis")
                    passo(n: 6, texto: "Copie o Client ID e cole aqui")
                }
                .padding(.vertical, 4)
            }
        } header: { RockSectionHeader(title: "Configuração") }
    }

    private func passo(n: Int, texto: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(n).")
                .font(.caption.weight(.heavy))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 16, alignment: .leading)
            Text(texto)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
