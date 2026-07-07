using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyAgree.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "agreement_templates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Domain = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Key = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    SourceUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    HtmlTemplate = table.Column<string>(type: "text", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_agreement_templates", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "agreement_template_fields",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AgreementTemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    FieldId = table.Column<int>(type: "integer", nullable: false),
                    Mode = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "Required")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_agreement_template_fields", x => x.Id);
                    table.ForeignKey(
                        name: "FK_agreement_template_fields_agreement_templates_AgreementTemp~",
                        column: x => x.AgreementTemplateId,
                        principalTable: "agreement_templates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "agreement_template_translations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    AgreementTemplateId = table.Column<Guid>(type: "uuid", nullable: false),
                    Language = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    Title = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_agreement_template_translations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_agreement_template_translations_agreement_templates_Agreeme~",
                        column: x => x.AgreementTemplateId,
                        principalTable: "agreement_templates",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_agreement_template_fields_AgreementTemplateId_FieldId",
                table: "agreement_template_fields",
                columns: new[] { "AgreementTemplateId", "FieldId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_agreement_template_translations_AgreementTemplateId_Language",
                table: "agreement_template_translations",
                columns: new[] { "AgreementTemplateId", "Language" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_agreement_templates_Domain",
                table: "agreement_templates",
                column: "Domain");

            migrationBuilder.CreateIndex(
                name: "IX_agreement_templates_Key",
                table: "agreement_templates",
                column: "Key",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "agreement_template_fields");

            migrationBuilder.DropTable(
                name: "agreement_template_translations");

            migrationBuilder.DropTable(
                name: "agreement_templates");
        }
    }
}
