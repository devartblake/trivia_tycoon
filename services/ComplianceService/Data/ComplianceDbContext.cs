using Microsoft.EntityFrameworkCore;

namespace ComplianceService.Data;

public class ComplianceDbContext(DbContextOptions<ComplianceDbContext> options) : DbContext(options)
{
    public DbSet<ComplianceRecord>  ComplianceRecords  => Set<ComplianceRecord>();
    public DbSet<KycRecord>         KycRecords         => Set<KycRecord>();
    public DbSet<AgeRecord>         AgeRecords         => Set<AgeRecord>();
    public DbSet<AmlRecord>         AmlRecords         => Set<AmlRecord>();
    public DbSet<AuditLogEntry>     AuditLog           => Set<AuditLogEntry>();
    public DbSet<ConsentRecord>     ConsentRecords     => Set<ConsentRecord>();
    public DbSet<DataSubjectRequest> DataSubjectRequests => Set<DataSubjectRequest>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AuditLogEntry>()
            .HasIndex(e => e.UserId);
        modelBuilder.Entity<AuditLogEntry>()
            .HasIndex(e => e.CreatedAt);

        modelBuilder.Entity<AmlRecord>()
            .HasIndex(r => r.UserId);
        modelBuilder.Entity<AmlRecord>()
            .HasIndex(r => r.CreatedAt);

        modelBuilder.Entity<KycRecord>()
            .HasIndex(r => r.UserId);

        modelBuilder.Entity<ConsentRecord>()
            .HasIndex(c => c.UserId);

        modelBuilder.Entity<DataSubjectRequest>()
            .HasIndex(r => r.UserId);
    }
}
