using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyAgree.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDealFirstPartySignature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "FirstPartyName",
                table: "deals",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FirstPartySignedAt",
                table: "deals",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FirstPartyName",
                table: "deals");

            migrationBuilder.DropColumn(
                name: "FirstPartySignedAt",
                table: "deals");
        }
    }
}
