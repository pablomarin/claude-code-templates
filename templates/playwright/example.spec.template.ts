/**
 * Example spec written by the main implementation agent in Phase 6.2c,
 * using the observed selectors from the verify-e2e agent's report.
 *
 * Format: one test per use case (UC1, UC2, ...) from the plan file.
 * Each test is a deterministic replay of the agent's exploratory run.
 */
import { test, expect } from "@playwright/test";

test.describe("Feature: <feature-name>", () => {
  // UC1: <Intent from plan file>
  test("UC1: User creates a new item @smoke", async ({ page }) => {
    // ARRANGE — setup path from use case (e.g., authenticated via fixture)
    await page.goto("/items");

    // ACT — steps from use case
    await page.getByRole("button", { name: "New item" }).click();
    await page.getByLabel("Name").fill("Test item");
    await page.getByRole("button", { name: "Create" }).click();

    // VERIFY — assertions from use case
    await expect(page.getByText("Test item")).toBeVisible();

    // PERSIST — reload and confirm
    await page.reload();
    await expect(page.getByText("Test item")).toBeVisible();
  });

  // UC2: <Edge case from plan file>
  test("UC2: User cannot create item without required field", async ({
    page,
  }) => {
    await page.goto("/items/new");
    await page.getByRole("button", { name: "Create" }).click();
    await expect(page.getByText(/name is required/i)).toBeVisible();
  });
});
