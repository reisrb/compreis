import SwiftUI

struct PerfilView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject private var auth = GoogleAuth.shared
    @State private var connecting = false
    @State private var showClientIdSheet = false
    @State private var exportURL: URL?
    @State private var showExportError = false
    @State private var showImportPicker = false
    @State private var importResultMessage: String?
    @State private var showImportError = false
    @State private var importErrorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.bottom, 28)

                    VStack(spacing: 12) {
                        if auth.isConnected {
                            sheetsCard
                            disconnectButton
                        } else {
                            signInCard
                        }
                        NavigationLink(destination: ProdutosView()) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.indigo.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "shippingbox.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color.indigo)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Produtos")
                                        .font(.body.weight(.bold))
                                        .foregroundStyle(.primary)
                                    Text("Gerenciar histórico de produtos")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        tutorialCard
                        NavigationLink(destination: TemaView()) {
                            HStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.accentSubtle)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(AppTheme.accent)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Aparência")
                                        .font(.body.weight(.bold))
                                        .foregroundStyle(.primary)
                                    Text("Tema, cores e estilo de fundo")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        setupCard
                        exportCard
                        importCard
                        icloudCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .tint(AppTheme.accent)
        }
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                do {
                    let (listas, itens) = try ExportService.importarJSON(url: url, context: context)
                    importResultMessage = "\(listas) \(listas == 1 ? "lista" : "listas") e \(itens) \(itens == 1 ? "item importado" : "itens importados")"
                } catch {
                    importErrorMessage = error.localizedDescription
                    showImportError = true
                }
            case .failure(let error):
                importErrorMessage = error.localizedDescription
                showImportError = true
            }
        }
        .alert("Erro ao importar", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .sheet(isPresented: $showClientIdSheet) {
            ClientIdSheet { id in
                auth.clientId = id
                showClientIdSheet = false
                connecting = true
                Task {
                    await auth.signIn()
                    connecting = false
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(auth.isConnected ? AppTheme.accentSubtle : Color.secondary.opacity(0.1))
                    .frame(width: 88, height: 88)
                    .overlay(Circle().strokeBorder(
                        auth.isConnected ? AppTheme.accentBorder : Color.clear,
                        lineWidth: 1))

                if auth.isConnected, let email = auth.email {
                    Text(initials(from: email))
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(AppTheme.accent)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
            }
            .rockGlow(radius: auth.isConnected ? 12 : 0)
            .padding(.top, 16)

            if auth.isConnected {
                VStack(spacing: 4) {
                    Text(nameFrom(email: auth.email))
                        .font(.title3.weight(.heavy))
                    Text(auth.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 4) {
                    Text("Sem conta vinculada")
                        .font(.title3.weight(.heavy))
                    Text("Entre com Google para sincronizar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cards

    private var tutorialCard: some View {
        Button {
            TutorialManager.shared.start(resetTab: { _ in })
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.teal.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "hand.point.up.left.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.teal)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Tutorial")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Revisar como usar o app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var signInCard: some View {
        Button {
            if auth.clientId.isEmpty {
                showClientIdSheet = true
            } else {
                connecting = true
                Task {
                    await auth.signIn()
                    connecting = false
                }
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .frame(width: 36, height: 36)
                        .shadow(color: .black.opacity(0.12), radius: 2)
                    Text("G")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .red, .yellow, .green],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                if connecting {
                    ProgressView()
                        .tint(.white)
                    Text("Conectando…")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                } else {
                    Text("Entrar com Google")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 0.26, green: 0.52, blue: 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .rockBorder(cornerRadius: 14)
        }
        .disabled(connecting)

        .overlay(alignment: .bottomLeading) {
            if let erro = auth.errorMessage {
                Text(erro)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 44)
                    .padding(.leading, 4)
            }
        }
    }

    private var sheetsCard: some View {
        let sync = SyncService.shared
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.13, green: 0.59, blue: 0.33).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "tablecells.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 0.13, green: 0.59, blue: 0.33))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Google Sheets")
                        .font(.body.weight(.bold))
                    if sync.syncing {
                        Text("Sincronizando…")
                            .font(.caption).foregroundStyle(.secondary)
                    } else if let err = sync.lastError {
                        Text(err).font(.caption).foregroundStyle(.red).lineLimit(1)
                    } else if let ts = sync.lastSynced {
                        Text("Sincronizado \(ts.formatted(.relative(presentation: .named)))")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Compreis - Dados")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if sync.syncing {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .rockBorder(cornerRadius: 14)
    }

    private var disconnectButton: some View {
        Button(role: .destructive) {
            auth.signOut()
        } label: {
            HStack {
                Spacer()
                Label("Desconectar conta Google", systemImage: "arrow.right.square")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .rockBorder(cornerRadius: 14)
        }
        .foregroundStyle(.red)
    }

    private var importCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.purple)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Importar dados")
                        .font(.body.weight(.bold))
                    if let msg = importResultMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Importa um arquivo JSON exportado pelo app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button(importResultMessage == nil ? "Importar" : "Importar mais") {
                    showImportPicker = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.purple)
            }
            .padding(16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .rockBorder(cornerRadius: 14)
    }

    private var icloudCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud")
                        .font(.body.weight(.bold))
                    Text("Backup automático — sobrevive troca de iPhone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.blue)
            }
            .padding(16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .rockBorder(cornerRadius: 14)
    }

    private var exportCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exportar dados")
                        .font(.body.weight(.bold))
                    Text("Gera um arquivo JSON com todas as listas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let url = exportURL {
                    ShareLink(item: url) {
                        Text("Compartilhar")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                } else {
                    Button("Exportar") {
                        if let url = try? ExportService.exportarJSON(context: context) {
                            exportURL = url
                        } else {
                            showExportError = true
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                }
            }
            .padding(16)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .rockBorder(cornerRadius: 14)
        .alert("Erro ao exportar", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            RockSectionHeader(title: "Como configurar")
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 10) {
                passo(n: 1, texto: "Abra console.cloud.google.com")
                passo(n: 2, texto: "Crie um projeto \"Compreis\"")
                passo(n: 3, texto: "Ative Google Sheets API e Google Drive API")
                passo(n: 4, texto: "Credenciais → OAuth 2.0 → tipo iOS")
                passo(n: 5, texto: "Bundle ID: com.rafaelreis.compreis")
                passo(n: 6, texto: "Copie o Client ID e cole ao entrar")
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            Link(destination: URL(string: "https://console.cloud.google.com")!) {
                HStack {
                    Text("Abrir Google Cloud Console")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(16)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .rockBorder(cornerRadius: 14)
    }

    // MARK: - Helpers

    private func initials(from email: String) -> String {
        let parts = email.split(separator: "@").first?.split(separator: ".") ?? []
        let letters = parts.prefix(2).compactMap { $0.first.map { String($0).uppercased() } }
        return letters.joined()
    }

    private func nameFrom(email: String?) -> String {
        guard let email else { return "Usuário" }
        let local = email.split(separator: "@").first ?? ""
        return local.split(separator: ".").map { $0.capitalized }.joined(separator: " ")
    }

    private func passo(n: Int, texto: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(n)")
                .font(.caption.weight(.heavy))
                .foregroundStyle(.black)
                .frame(width: 18, height: 18)
                .background(AppTheme.accent)
                .clipShape(Circle())
            Text(texto)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Client ID Sheet

private struct ClientIdSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (String) -> Void

    @State private var text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("XXXXXX.apps.googleusercontent.com", text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.footnote.monospaced())
                } header: {
                    RockSectionHeader(title: "Client ID do Google Cloud")
                } footer: {
                    Text("Cole o Client ID OAuth 2.0 gerado no Google Cloud Console para o bundle com.rafaelreis.compreis.")
                }
            }
            .navigationTitle("Configurar Google")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar e Entrar") { onSave(text) }
                        .disabled(text.isEmpty)
                        .fontWeight(.heavy)
                        .tint(AppTheme.accent)
                }
            }
        }
    }
}
