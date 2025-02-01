import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure user can store a new key",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("flux-key", "store-key", 
        [types.ascii("encrypted-data"), types.uint(100)], 
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, "(ok u0)");
  }
});

Clarinet.test({
  name: "Ensure only owner can grant access",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("flux-key", "store-key",
        [types.ascii("encrypted-data"), types.uint(100)],
        wallet_1.address
      ),
      Tx.contractCall("flux-key", "grant-access",
        [types.uint(0), types.principal(wallet_2.address)],
        wallet_2.address
      )
    ]);

    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, "(err u101)");
  }
});

Clarinet.test({
  name: "Ensure access can be revoked",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("flux-key", "store-key",
        [types.ascii("encrypted-data"), types.uint(100)],
        wallet_1.address
      ),
      Tx.contractCall("flux-key", "grant-access",
        [types.uint(0), types.principal(wallet_2.address)],
        wallet_1.address
      ),
      Tx.contractCall("flux-key", "revoke-access",
        [types.uint(0), types.principal(wallet_2.address)],
        wallet_1.address
      ),
      Tx.contractCall("flux-key", "get-key-data",
        [types.uint(0)],
        wallet_2.address
      )
    ]);

    assertEquals(block.receipts[3].result, "(err u101)");
  }
});
