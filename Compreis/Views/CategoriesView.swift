import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomCategory.createdAt) private var customCats: [CustomCategory]

    @State private var showNew = false
    @State private var editing: CustomCategory?

    var body: some View {
        List {
            Section {
                ForEach(ItemCategory.allCases, id: \.self) { cat in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(cat.color.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: cat.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(cat.color)
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
                    Button { editing = cat } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(cat.color.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(cat.color)
                            }
                            Text(cat.name).font(.body).foregroundStyle(.primary)
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
                Button { showNew = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showNew) { CategoryEditSheet(category: nil) }
        .sheet(item: $editing) { cat in CategoryEditSheet(category: cat) }
    }
}

// MARK: - Edit sheet

private let iconOptions = [
    "tag", "fork.knife", "carrot.fill", "fish.fill", "basket.fill",
    "cup.and.saucer.fill", "house.fill", "cart.fill", "bag.fill", "leaf.fill",
    "drop.fill", "flame.fill", "snowflake", "pills.fill", "bandage.fill",
    "sparkles", "star.fill", "heart.fill", "bolt.fill", "gift.fill"
]

private struct CategoryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var category: CustomCategory?

    @State private var name = ""
    @State private var icon = "tag"
    @State private var color = Color.gray

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag").foregroundStyle(AppTheme.accent).frame(width: 20)
                        TextField("Category name", text: $name)
                    }
                } header: { Text("Name") }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { opt in
                            Button { icon = opt } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(icon == opt ? color.opacity(0.2) : Color.secondary.opacity(0.10))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(icon == opt ? color : Color.clear, lineWidth: 2)
                                        )
                                    Image(systemName: opt)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(icon == opt ? color : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: { Text("Icon") }

                Section {
                    ColorPicker("Colour", selection: $color, supportsOpacity: false)
                } header: { Text("Colour") }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(color.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: icon)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(color)
                            }
                            if !name.isEmpty {
                                Text(name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(color)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                } header: { Text("Preview") }
            }
            .navigationTitle(category == nil ? "New category" : "Edit category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalName = name.trimmingCharacters(in: .whitespaces)
                        let hexStr = color.toHex()
                        if let cat = category {
                            cat.name = finalName
                            cat.icon = icon
                            cat.colorHex = hexStr
                        } else {
                            context.insert(CustomCategory(name: finalName, icon: icon, colorHex: hexStr))
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .tint(AppTheme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let cat = category {
                    name = cat.name
                    icon = cat.icon
                    color = cat.color
                }
            }
        }
    }
}
