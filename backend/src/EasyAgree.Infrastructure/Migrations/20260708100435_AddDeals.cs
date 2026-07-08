using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyAgree.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDeals : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "deals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TemplateKey = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    RequestText = table.Column<string>(type: "text", nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    GeneratedHtml = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_deals", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_deals_TemplateKey",
                table: "deals",
                column: "TemplateKey");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "deals");
        }
    }
}
