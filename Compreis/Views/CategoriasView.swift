import SwiftUI
import SwiftData

struct CategoriasView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CategoriaCustom.criadaEm) private var customCats: [CategoriaCustom]

    @State private var showNova = false
    @State private var editando: CategoriaCustom?

    var body: some View {
        List {
            Section {
                ForEach(Categoria.allCases, id: \.self) { cat in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cat.cor.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: cat.icone)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(cat.cor)
                        }
                        Text(cat.rawValue).font(.body)
                        Spacer()
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: { Text("Default categories") }

            Section {
                if customCats.isEmpty {
                    Label("No category created", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(customCats) { cat in
                    Button { editando = cat } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cat.cor.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: cat.icone)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(cat.cor)
                            }
                            Text(cat.nome).font(.body).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            context.delete(cat)
                        } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            } header: { Text("My categories") }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNova = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showNova) { CategoriaEditSheet(categoria: nil) }
        .sheet(item: $editando) { cat in CategoriaEditSheet(categoria: cat) }
    }
}

// MARK: - Edit sheet

private let iconeOpcoes = [
    "tag", "fork.knife", "carrot.fill", "fish.fill", "basket.fill",
    "cup.and.saucer.fill", "house.fill", "cart.fill", "bag.fill", "leaf.fill",
    "drop.fill", "flame.fill", "snowflake", "pills.fill", "bandage.fill",
    "sparkles", "star.fill", "heart.fill", "bolt.fill", "gift.fill"
]

private struct CategoriaEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var categoria: CategoriaCustom?

    @State private var nome = ""
    @State private var icone = "tag"
    @State private var cor = Color.gray

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag").foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("Category name", text: $nome)
                    }
                } header: { Text("Name") }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(iconeOpcoes, id: \.self) { opt in
                            Button { icone = opt } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(icone == opt ? cor.opacity(0.2) : Color.secondary.opacity(0.10))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(icone == opt ? cor : Color.clear, lineWidth: 2)
                                        )
                                    Image(systemName: opt)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(icone == opt ? cor : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Icon") }

                Section {
                    ColorPicker("Colour", selection: $cor, supportsOpacity: false)
                } header: { Text("Colour") }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cor.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: icone)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(cor)
                            }
                            if !nome.isEmpty {
                                Text(nome)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(cor)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: { Text("Preview") }
            }
            .navigationTitle(categoria == nil ? "New category" : "Edit category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let nomeFinal = nome.trimmingCharacters(in: .whitespaces)
                        let hexStr = cor.toHex()
                        if let cat = categoria {
                            cat.nome = nomeFinal
                            cat.icone = icone
                            cat.corHex = hexStr
                        } else {
                            context.insert(CategoriaCustom(nome: nomeFinal, icone: icone, corHex: hexStr))
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let cat = categoria {
                    nome = cat.nome
                    icone = cat.icone
                    cor = cat.cor
                }
            }
        }
    }
}
