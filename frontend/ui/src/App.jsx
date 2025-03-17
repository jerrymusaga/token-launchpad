import { useState, useEffect } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import {
  useAccount,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { gql, useQuery } from "@apollo/client";
import ABI from "../src/contractABI/LaunchPad.json";

// GraphQL Queries
const GET_USER_ERC20_TOKENS = gql`
  query GetUserERC20Tokens($creator: String!) {
    erc20TokenCreateds(where: { creator: $creator }) {
      id
      creator
      tokenAddress
      name
      symbol
      quantity
      blockTimestamp
    }
  }
`;

const GET_USER_ERC721_TOKENS = gql`
  query GetUserERC721Tokens($creator: String!) {
    erc721TokenCreateds(where: { creator: $creator }) {
      id
      creator
      tokenAddress
      name
      symbol
      blockTimestamp
    }
  }
`;

function App() {
  const { isConnected, address } = useAccount();
  const { writeContractAsync, isPending: isWritePending } = useWriteContract();
  const [activeTab, setActiveTab] = useState("erc20");
  const [transactionHash, setTransactionHash] = useState("");

  const [tokenName, setTokenName] = useState("");
  const [tokenSymbol, setTokenSymbol] = useState("");
  const [tokenQuantity, setTokenQuantity] = useState(1000);
  const [tokenUri, setTokenUri] = useState("");
  const [mintInitial, setMintInitial] = useState(true);

  const {
    isLoading: isConfirming,
    isSuccess: isConfirmed,
    data: receipt,
  } = useWaitForTransactionReceipt({
    hash: transactionHash,
  });

  const launchpadContractAddress = "0xCED4dF2d4285f5315Ef5b28055e2D61ea9041B40";

  // Apollo useQuery for ERC20 tokens - Only run when we're on the mytokens tab and address is available
  const {
    loading: erc20Loading,
    error: erc20Error,
    data: erc20Data,
    refetch: refetchErc20Tokens,
  } = useQuery(GET_USER_ERC20_TOKENS, {
    variables: { creator: address ? address.toLowerCase() : "" },
    skip: !address || activeTab !== "mytokens",
    fetchPolicy: "cache-and-network",
    notifyOnNetworkStatusChange: true,
  });

  // Apollo useQuery for ERC721 tokens - Only run when we're on the mytokens tab and address is available
  const {
    loading: erc721Loading,
    error: erc721Error,
    data: erc721Data,
    refetch: refetchErc721Tokens,
  } = useQuery(GET_USER_ERC721_TOKENS, {
    variables: { creator: address ? address.toLowerCase() : "" },
    skip: !address || activeTab !== "mytokens",
    fetchPolicy: "cache-and-network",
    notifyOnNetworkStatusChange: true,
  });

  // Refetch tokens when transaction is confirmed
  useEffect(() => {
    if (isConfirmed && activeTab === "mytokens" && address) {
      refetchErc20Tokens();
      refetchErc721Tokens();
    }
  }, [isConfirmed, activeTab, address]);

  // Handle tab change - refetch data when navigating to My Tokens tab
  useEffect(() => {
    if (activeTab === "mytokens" && address) {
      refetchErc20Tokens();
      refetchErc721Tokens();
    }
  }, [activeTab, address]);

  const fetchUserTokens = () => {
    if (address) {
      refetchErc20Tokens();
      refetchErc721Tokens();
    }
  };

  const createERC20Token = async (e) => {
    e.preventDefault();

    try {
      const hash = await writeContractAsync({
        address: launchpadContractAddress,
        abi: ABI.abi,
        functionName: "createToken",
        args: [tokenName, tokenSymbol, tokenQuantity],
      });

      setTransactionHash(hash);
      resetForm();
    } catch (error) {
      console.error("Failed to create ERC20 token:", error);
    }
  };

  const createNFT = async (e) => {
    e.preventDefault();

    try {
      const hash = await writeContractAsync({
        address: launchpadContractAddress,
        abi: ABI.abi,
        functionName: "createNFT",
        args: [tokenName, tokenSymbol, tokenUri, mintInitial],
      });

      setTransactionHash(hash);
      resetForm();
    } catch (error) {
      console.error("Failed to create NFT:", error);
    }
  };

  const resetForm = () => {
    setTokenName("");
    setTokenSymbol("");
    setTokenQuantity(1000);
    setTokenUri("");
  };

  // Safely access token arrays, providing empty arrays as fallbacks
  const erc20Tokens = erc20Data?.erc20TokenCreateds || [];
  const erc721Tokens = erc721Data?.erc721TokenCreateds || [];

  return (
    <div className="max-w-lg mx-auto mt-8 p-6 bg-white rounded-lg shadow-md">
      <h1 className="text-2xl font-bold mb-6">Token LaunchPad</h1>

      <div className="mb-6">
        <ConnectButton />
      </div>

      {isConnected ? (
        <>
          <div className="mb-4 flex">
            <button
              className={`flex-1 py-2 ${
                activeTab === "erc20" ? "bg-blue-500 text-white" : "bg-gray-200"
              }`}
              onClick={() => setActiveTab("erc20")}
            >
              Create ERC20 Token
            </button>
            <button
              className={`flex-1 py-2 ${
                activeTab === "nft" ? "bg-blue-500 text-white" : "bg-gray-200"
              }`}
              onClick={() => setActiveTab("nft")}
            >
              Create NFT
            </button>
            <button
              className={`flex-1 py-2 ${
                activeTab === "mytokens"
                  ? "bg-blue-500 text-white"
                  : "bg-gray-200"
              }`}
              onClick={() => setActiveTab("mytokens")}
            >
              My Tokens
            </button>
          </div>

          {activeTab === "erc20" ? (
            <form onSubmit={createERC20Token} className="space-y-4">
              <div>
                <label className="block mb-1">Token Name</label>
                <input
                  type="text"
                  className="w-full border rounded p-2"
                  value={tokenName}
                  onChange={(e) => setTokenName(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block mb-1">Token Symbol</label>
                <input
                  type="text"
                  className="w-full border rounded p-2"
                  value={tokenSymbol}
                  onChange={(e) => setTokenSymbol(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block mb-1">Initial Supply</label>
                <input
                  type="number"
                  className="w-full border rounded p-2"
                  value={tokenQuantity}
                  onChange={(e) => setTokenQuantity(Number(e.target.value))}
                  min="1"
                  required
                />
              </div>
              <button
                type="submit"
                className="w-full bg-blue-500 text-white py-2 rounded hover:bg-blue-600 disabled:bg-gray-400"
                disabled={isWritePending || isConfirming}
              >
                {isWritePending ? "Creating..." : "Create ERC20 Token"}
              </button>
            </form>
          ) : activeTab === "nft" ? (
            <form onSubmit={createNFT} className="space-y-4">
              <div>
                <label className="block mb-1">NFT Name</label>
                <input
                  type="text"
                  className="w-full border rounded p-2"
                  value={tokenName}
                  onChange={(e) => setTokenName(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block mb-1">NFT Symbol</label>
                <input
                  type="text"
                  className="w-full border rounded p-2"
                  value={tokenSymbol}
                  onChange={(e) => setTokenSymbol(e.target.value)}
                  required
                />
              </div>
              <div>
                <label className="block mb-1">Token URI</label>
                <input
                  type="text"
                  className="w-full border rounded p-2"
                  value={tokenUri}
                  onChange={(e) => setTokenUri(e.target.value)}
                />
              </div>
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="mintInitial"
                  checked={mintInitial}
                  onChange={(e) => setMintInitial(e.target.checked)}
                />
                <label htmlFor="mintInitial" className="ml-2">
                  Mint initial token
                </label>
              </div>
              <button
                type="submit"
                className="w-full bg-blue-500 text-white py-2 rounded hover:bg-blue-600 disabled:bg-gray-400"
                disabled={isWritePending || isConfirming}
              >
                {isWritePending ? "Creating..." : "Create NFT"}
              </button>
            </form>
          ) : (
            // My Tokens tab content
            <div className="mt-4">
              <h2 className="text-xl font-semibold mb-4">My Tokens</h2>

              {erc20Loading || erc721Loading ? (
                <div className="text-center py-8">Loading your tokens...</div>
              ) : erc20Error || erc721Error ? (
                <div className="text-center py-8 text-red-500">
                  Error loading tokens. Please try again.
                  <pre className="mt-2 text-xs">
                    {erc20Error ? erc20Error.message : ""}
                    {erc721Error ? erc721Error.message : ""}
                  </pre>
                </div>
              ) : (
                <>
                  <div className="mb-6">
                    <h3 className="text-lg font-medium mb-2">ERC20 Tokens</h3>
                    {erc20Tokens.length === 0 ? (
                      <p className="text-gray-500">
                        You haven't created any ERC20 tokens yet.
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {erc20Tokens.map((token) => (
                          <div key={token.id} className="border rounded p-3">
                            <div className="font-medium">
                              {token.name} ({token.symbol})
                            </div>
                            <div className="text-sm text-gray-500 break-all">
                              Address: {token.tokenAddress}
                            </div>
                            <div className="text-sm text-gray-500">
                              Initial Supply: {token.quantity}
                            </div>
                            <div className="text-sm text-gray-500">
                              Created:{" "}
                              {new Date(
                                parseInt(token.blockTimestamp) * 1000
                              ).toLocaleString()}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  <div>
                    <h3 className="text-lg font-medium mb-2">
                      NFT Collections
                    </h3>
                    {erc721Tokens.length === 0 ? (
                      <p className="text-gray-500">
                        You haven't created any NFT collections yet.
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {erc721Tokens.map((token) => (
                          <div key={token.id} className="border rounded p-3">
                            <div className="font-medium">
                              {token.name} ({token.symbol})
                            </div>
                            <div className="text-sm text-gray-500 break-all">
                              Address: {token.tokenAddress}
                            </div>
                            <div className="text-sm text-gray-500">
                              Created:{" "}
                              {new Date(
                                parseInt(token.blockTimestamp) * 1000
                              ).toLocaleString()}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </>
              )}

              <button
                className="mt-4 w-full bg-gray-200 text-gray-800 py-2 rounded hover:bg-gray-300"
                onClick={fetchUserTokens}
                disabled={erc20Loading || erc721Loading}
              >
                {erc20Loading || erc721Loading
                  ? "Loading..."
                  : "Refresh Tokens"}
              </button>
            </div>
          )}

          {transactionHash && (
            <div className="mt-4 p-4 border rounded">
              <p className="font-medium">Transaction Status:</p>
              {isConfirming && (
                <p className="text-yellow-600">Confirming transaction...</p>
              )}
              {isConfirmed && (
                <div className="text-green-600">
                  <p>✅ Transaction confirmed!</p>
                  <p className="text-sm break-all mt-1">
                    Hash: {transactionHash}
                  </p>
                  {receipt?.to && (
                    <p className="text-sm mt-1">
                      Token created at: {receipt.to}
                    </p>
                  )}
                </div>
              )}
            </div>
          )}
        </>
      ) : (
        <div className="text-center py-6">
          <p className="text-lg">Connect your wallet to create tokens</p>
        </div>
      )}
    </div>
  );
}

export default App;
