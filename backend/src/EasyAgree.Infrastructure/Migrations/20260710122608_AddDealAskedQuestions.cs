using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyAgree.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDealAskedQuestions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AskedQuestionsJson",
                table: "deals",
                type: "jsonb",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AskedQuestionsJson",
                table: "deals");
        }
    }
}
