import SwiftUI
import FirebaseFirestore

struct AdminReportsView: View {
    @StateObject private var firestoreService = FirestoreService()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedReport: Report?
    @State private var showReportDetailsSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.semiDark).ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading Reports")
                        .foregroundColor(.white)
                        .tint(.white)
                } else if firestoreService.reports.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("No Reports")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("There are no reports to review at this time.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    reportsList
                }
            }
            .navigationTitle("Content Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.darkest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        loadReports()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .task {
                loadReports()
            }
            .sheet(isPresented: $showReportDetailsSheet) {
                if let report = selectedReport {
                    ReportDetailView(report: report)
                        .environmentObject(firestoreService)
                }
            }
        }
    }
    
    private var reportsList: some View {
        List {
            ForEach(firestoreService.reports) { report in
                Button {
                    selectedReport = report
                    showReportDetailsSheet = true
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(report.reportedUrbexName)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            statusBadge(for: report.status)
                        }
                        
                        Text("Reported by: \(report.reporterUsername)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Text("Reason: \(report.reason.rawValue)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text(formatDate(report.timestamp.dateValue()))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.greyish)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func statusBadge(for status: Report.ReportStatus) -> some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(statusColor(for: status))
            )
            .foregroundColor(.white)
    }
    
    private func statusColor(for status: Report.ReportStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .reviewed:
            return .blue
        case .resolved:
            return .green
        case .dismissed:
            return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadReports() {
        isLoading = true
        
        Task {
            do {
                try await firestoreService.fetchReportsForAdmin()
                
                DispatchQueue.main.async {
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct ReportDetailView: View {
    let report: Report
    @EnvironmentObject var firestoreService: FirestoreService
    @Environment(\.dismiss) var dismiss
    @State private var selectedStatus: Report.ReportStatus
    @State private var urbex: Urbex?
    @State private var isLoading = false
    @State private var showUrbexDetails = false
    @State private var showDeleteAlert = false
    @State private var showSuccessAlert = false
    
    init(report: Report) {
        self.report = report
        _selectedStatus = State(initialValue: report.status)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.semiDark).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        reportInfoSection
                        
                        if let urbex = urbex {
                            urbexInfoSection(urbex: urbex)
                        } else if isLoading {
                            ProgressView("Loading urbex details")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Report Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.darkest, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task {
                await loadUrbexDetails()
            }
            .alert("Delete Urbex", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteUrbex()
                }
            } message: {
                Text("Are you sure you want to delete this urbex? This action cannot be undone.")
            }
            .alert("Status Updated", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("The report status has been updated successfully.")
            }
            .sheet(isPresented: $showUrbexDetails) {
                if let urbex = urbex {
                    UrbexDetailsView(urbex: urbex)
                }
            }
        }
    }
    
    private var reportInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Report Information")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Divider()
                    .background(Color.white.opacity(0.3))
            }
            
            HStack {
                Text("Status:")
                    .foregroundColor(.white.opacity(0.7))
                
                Menu {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach([Report.ReportStatus.pending, .reviewed, .resolved, .dismissed], id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                } label: {
                    Text(selectedStatus.rawValue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(statusColor(for: selectedStatus))
                        )
                        .foregroundColor(.white)
                }
            }
            
            detailRow(title: "Reported by", value: report.reporterUsername)
            
            detailRow(title: "Report date", value: formatDate(report.timestamp.dateValue()))
            
            detailRow(title: "Reason", value: report.reason.rawValue)
            
            if !report.additionalComments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional comments:")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(report.additionalComments)
                        .foregroundColor(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.greyish)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.darkest)
        )
    }
    
    private func urbexInfoSection(urbex: Urbex) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reported Content")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Divider()
                    .background(Color.white.opacity(0.3))
            }
            
            if let url = URL(string: urbex.imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            detailRow(title: "Urbex name", value: urbex.name)
            
            detailRow(title: "Added by", value: urbex.addedBy)
            
            Button("View full urbex details") {
                showUrbexDetails = true
            }
            .font(.subheadline)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.greyish)
            .cornerRadius(8)
            .foregroundColor(.white)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.darkest)
        )
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await updateReportStatus()
                }
            } label: {
                Text("Update Status")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            
            Button {
                showDeleteAlert = true
            } label: {
                Text("Delete Content")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            }
            .disabled(urbex == nil)
            .opacity(urbex == nil ? 0.5 : 1.0)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text("\(title):")
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    private func statusColor(for status: Report.ReportStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .reviewed:
            return .blue
        case .resolved:
            return .green
        case .dismissed:
            return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func loadUrbexDetails() async {
        isLoading = true
        if let urbexDetails = await firestoreService.fetchUrbexByID(report.urbexID) {
            DispatchQueue.main.async {
                self.urbex = urbexDetails
                self.isLoading = false
            }
        } else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func updateReportStatus() async {
        guard let reportID = report.id, selectedStatus != report.status else { return }
        
        do {
            try await firestoreService.updateReportStatus(reportID: reportID, status: selectedStatus)
            await firestoreService.fetchReportsForAdmin()
            
            DispatchQueue.main.async {
                showSuccessAlert = true
            }
        } catch {
            print("Error updating report status: \(error.localizedDescription)")
        }
    }
    
    private func deleteUrbex() {
        guard let urbex = urbex else { return }
        
        Task {
            await firestoreService.deleteUrbex(urbex)
            
            // Update report status to resolved
            if let reportID = report.id {
                try? await firestoreService.updateReportStatus(reportID: reportID, status: .resolved)
            }
            
            await firestoreService.fetchReportsForAdmin()
            
            DispatchQueue.main.async {
                dismiss()
            }
        }
    }
}

#Preview {
    AdminReportsView()
} 