import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure brand registration works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'register-brand', [
        types.ascii("Test Brand")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify brand data
    let brandBlock = chain.mineBlock([
      Tx.contractCall('trend-vault', 'get-brand', [
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);
    
    const brandData = brandBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(brandData.verified, types.bool(false));
    assertEquals(brandData.name, types.ascii("Test Brand"));
  },
});

Clarinet.test({
  name: "Test product listing and purchasing flow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Register brand first
    let block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'register-brand', [
        types.ascii("Test Brand")
      ], wallet1.address)
    ]);
    
    // List a product
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'list-product', [
        types.ascii("Test Product"),
        types.ascii("A great product"),
        types.uint(1000000)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Purchase the product
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'purchase-product', [
        types.uint(1)
      ], wallet2.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify product is no longer available
    let productBlock = chain.mineBlock([
      Tx.contractCall('trend-vault', 'get-product', [
        types.uint(1)
      ], wallet1.address)
    ]);
    
    const productData = productBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(productData.available, types.bool(false));
  },
});

Clarinet.test({
  name: "Test auction system validation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    
    // Register brand
    let block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'register-brand', [
        types.ascii("Test Brand")
      ], wallet1.address)
    ]);
    
    // Try creating auction with invalid duration
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'create-auction', [
        types.ascii("Auction Item"),
        types.ascii("Special auction item"),
        types.uint(1000000),
        types.uint(5) // Less than minimum duration
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(108); // err-invalid-duration
    
    // Create valid auction
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'create-auction', [
        types.ascii("Auction Item"),
        types.ascii("Special auction item"),
        types.uint(1000000),
        types.uint(20)
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
  },
});

Clarinet.test({
  name: "Test review system validation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    // Try adding invalid rating
    let block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'add-review', [
        types.uint(1),
        types.uint(6), // Greater than max rating
        types.ascii("Great product!")
      ], wallet2.address)
    ]);
    
    block.receipts[0].result.expectErr(109); // err-invalid-rating
    
    // Add valid review
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'add-review', [
        types.uint(1),
        types.uint(5),
        types.ascii("Great product!")
      ], wallet2.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify review
    let reviewBlock = chain.mineBlock([
      Tx.contractCall('trend-vault', 'get-review', [
        types.uint(1),
        types.principal(wallet2.address)
      ], wallet1.address)
    ]);
    
    const reviewData = reviewBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(reviewData.rating, types.uint(5));
    assertEquals(reviewData.comment, types.ascii("Great product!"));
  },
});
