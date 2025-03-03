// [Previous test imports remain unchanged]

Clarinet.test({
  name: "Test enhanced batch listing validation",
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
    
    // Test valid batch
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'batch-list-products', [
        types.list([types.ascii("Product 1"), types.ascii("Product 2")]),
        types.list([types.ascii("Desc 1"), types.ascii("Desc 2")]),
        types.list([types.uint(1000000), types.uint(2000000)]),
        types.list([types.uint(1), types.uint(1)])
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    // Test invalid price
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'batch-list-products', [
        types.list([types.ascii("Product 1")]),
        types.list([types.ascii("Desc 1")]),
        types.list([types.uint(0)]),
        types.list([types.uint(1)])
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(102); // err-invalid-price
    
    // Test invalid category
    block = chain.mineBlock([
      Tx.contractCall('trend-vault', 'batch-list-products', [
        types.list([types.ascii("Product 1")]),
        types.list([types.ascii("Desc 1")]),
        types.list([types.uint(1000000)]),
        types.list([types.uint(999)])
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectErr(110); // err-invalid-category
  },
});

// [Rest of the test file remains unchanged]
