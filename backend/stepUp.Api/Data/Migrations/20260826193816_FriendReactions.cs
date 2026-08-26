using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace stepUp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class FriendReactions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "FriendReactions",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "TEXT", nullable: false),
                    FriendId = table.Column<string>(type: "TEXT", nullable: false),
                    Date = table.Column<DateOnly>(type: "TEXT", nullable: false),
                    ReactionType = table.Column<string>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FriendReactions", x => new { x.UserId, x.FriendId, x.Date });
                    table.ForeignKey(
                        name: "FK_FriendReactions_Users_FriendId",
                        column: x => x.FriendId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_FriendReactions_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "UserId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_FriendReactions_FriendId",
                table: "FriendReactions",
                column: "FriendId");

            migrationBuilder.CreateIndex(
                name: "IX_FriendReactions_UserId_Date",
                table: "FriendReactions",
                columns: new[] { "UserId", "Date" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "FriendReactions");
        }
    }
}
