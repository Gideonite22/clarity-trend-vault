// [Previous test imports and content remains]

Clarinet.test({
  name: "Test category management and batch listing",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Add category
    let block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'add-category', [
        types.ascii("Electronics")
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Register brand
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'register-brand', [
        types.ascii("Test Brand")
      ], wallet1.address)
    ]);
    
    // Batch list products
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'batch-list-products', [
        types.list([types.ascii("Product 1"), types.ascii("Product 2")]),
        types.list([types.ascii("Desc 1"), types.ascii("Desc 2")]),
        types.list([types.uint(1000000), types.uint(2000000)]),
        types.list([types.uint(1), types.uint(1)])
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Verify products
    let product1Block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'get-product', [
        types.uint(1)
      ], wallet1.address)
    ]);
    
    const product1Data = product1Block.receipts[0].result.expectOk().expectSome();
    assertEquals(product1Data['category-id'], types.uint(1));
  },
});

// [Rest of the test file remains unchanged]
