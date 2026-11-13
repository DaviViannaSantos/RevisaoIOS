import SwiftUI
import Combine

struct ItemProva: Identifiable {
    let id = UUID()
    var materia: String
    var sala: String
    var dia: Date
    var revisada: Bool
}

class AgendaProvasViewModel: ObservableObject {
    @Published var provas: [ItemProva] = [
        ItemProva(materia: "Cálculo II", sala: "Lab 3", dia: Date().addingTimeInterval(86400 * 2), revisada: false),
        ItemProva(materia: "iOS Mobile", sala: "Sala 201", dia: Date().addingTimeInterval(86400 * 5), revisada: true),
        ItemProva(materia: "Banco de Dados", sala: "Lab 1", dia: Date().addingTimeInterval(86400 * 10), revisada: false),
        ItemProva(materia: "Redes", sala: "Sala 104", dia: Date().addingTimeInterval(86400 * 12), revisada: false)
    ]
    @Published var soPendentes: Bool = false
    
    var visiveis: [ItemProva] {
        let listaFiltrada = soPendentes ? provas.filter { !$0.revisada } : provas
        return listaFiltrada.sorted { $0.dia < $1.dia }
    }
    
    var pendentes: Int {
        provas.filter { !$0.revisada }.count
    }
    
    func adicionar(materia: String, sala: String, dia: Date) {
        let novaProva = ItemProva(
            materia: materia.trimmingCharacters(in: .whitespaces),
            sala: sala.trimmingCharacters(in: .whitespaces),
            dia: dia,
            revisada: false
        )
        provas.append(novaProva)
    }
    
    func apagar(id: UUID) {
        provas.removeAll { $0.id == id }
    }
    
    func definirRevisada(id: UUID, revisada: Bool) {
        if let index = provas.firstIndex(where: { $0.id == id }) {
            provas[index].revisada = revisada
        }
    }
    
    func prova(por id: UUID) -> ItemProva? {
        provas.first(where: { $0.id == id })
    }
}

struct AgendaProvasView: View {
    @StateObject private var viewModel = AgendaProvasViewModel()
    @State private var abreNovaProva = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Resumo") {
                    Text("Total de provas: \(viewModel.provas.count)")
                    Text("Provas pendentes: \(viewModel.pendentes)")
                    Toggle("Só as pendentes", isOn: $viewModel.soPendentes)
                }
                
                Section("Provas") {
                    ForEach(viewModel.visiveis) { prova in
                        NavigationLink(destination: ProvaDetalheView(viewModel: viewModel, id: prova.id)) {
                            VStack(alignment: .leading) {
                                Text(prova.materia)
                                    .font(.headline)
                                Text("\(prova.sala) • \(prova.revisada ? "Revisada" : "Pendente")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let id = viewModel.visiveis[index].id
                            viewModel.apagar(id: id)
                        }
                    }
                }
            }
            .navigationTitle("Provas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        abreNovaProva = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $abreNovaProva) {
                NovaProvaView(viewModel: viewModel)
            }
        }
    }
}

struct ProvaDetalheView: View {
    @ObservedObject var viewModel: AgendaProvasViewModel
    let id: UUID
    @Environment(\.dismiss) private var dismiss
    
    @State private var exibeAlertaApagar = false
    
    var prova: ItemProva? {
        viewModel.prova(por: id)
    }
    
    var body: some View {
        Form {
            if let prova = prova {
                LabeledContent("Sala", value: prova.sala)
                
                LabeledContent("Data") {
                    Text(prova.dia, format: .dateTime.day().month(.wide).year())
                }
                
                Toggle("Revisada", isOn: Binding(
                    get: { prova.revisada },
                    set: { novoValor in
                        viewModel.definirRevisada(id: id, revisada: novoValor)
                    }
                ))
                
                Button("Apagar", role: .destructive) {
                    exibeAlertaApagar = true
                }
            } else {
                Text("Prova não encontrada.")
            }
        }
        .navigationTitle(prova?.materia ?? "Detalhe")
        .alert("Apagar esta prova?", isPresented: $exibeAlertaApagar) {
            Button("Apagar", role: .destructive) {
                viewModel.apagar(id: id)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

struct NovaProvaView: View {
    @ObservedObject var viewModel: AgendaProvasViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var materia = ""
    @State private var sala = ""
    @State private var dia = Date()
    
    private var podeSalvar: Bool {
        !materia.trimmingCharacters(in: .whitespaces).isEmpty &&
        !sala.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Matéria", text: $materia)
                TextField("Sala", text: $sala)
                DatePicker("Dia", selection: $dia, displayedComponents: .date)
            }
            .navigationTitle("Nova prova")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        viewModel.adicionar(materia: materia, sala: sala, dia: dia)
                        dismiss()
                    }
                    .disabled(!podeSalvar)
                }
            }
        }
    }
}