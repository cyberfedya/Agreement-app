using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyAgree.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDealProfileIndexesAndCancelledStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_deals_ProfileId",
                table: "deals",
                column: "ProfileId");

            migrationBuilder.CreateIndex(
                name: "IX_deals_SecondPartyProfileId",
                table: "deals",
                column: "SecondPartyProfileId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_deals_ProfileId",
                table: "deals");

            migrationBuilder.DropIndex(
                name: "IX_deals_SecondPartyProfileId",
                table: "deals");
        }
    }
}
