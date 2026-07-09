using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyAgree.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDealSecondPartySignature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SecondPartyName",
                table: "deals",
                type: "character varying(300)",
                maxLength: 300,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "SecondPartySignedAt",
                table: "deals",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SecondPartyName",
                table: "deals");

            migrationBuilder.DropColumn(
                name: "SecondPartySignedAt",
                table: "deals");
        }
    }
}
