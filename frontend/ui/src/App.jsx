import { useState, useEffect } from "react";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import {
  useAccount,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import ABI from "../src/contractABI/LaunchPad.json";

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
  const [userTokens, setUserTokens] = useState({ erc20: [], erc721: [] });
  const [isLoadingTokens, setIsLoadingTokens] = useState(false);

  // useEffect(() => {
  //   if (address && activeTab === "mytokens") {
  //     fetchUserTokens();
  //   }
  // }, [address]);

  const {
    isLoading: isConfirming,
    isSuccess: isConfirmed,
    data: receipt,
  } = useWaitForTransactionReceipt({
    hash: transactionHash,
  });

  const launchpadContractAddress = "0xCED4dF2d4285f5315Ef5b28055e2D61ea9041B40";

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

  // const fetchUserTokens = async () => {
  //   if (!address) return;

  //   setIsLoadingTokens(true);

  //   try {
  //     // Uncomment the contract functions or use alternative approach
  //     // For now, we'll use a simpler way to get token lists
  //     const erc20Result = await readContract({
  //       address: launchpadContractAddress,
  //       abi: [], // ABI for erc20CreatorTokenAddresses
  //       functionName: "erc20CreatorTokenAddresses",
  //       args: [address],
  //     });

  //     const erc721Result = await readContract({
  //       address: launchpadContractAddress,
  //       abi: [], // ABI for erc721CreatorTokenAddresses
  //       functionName: "erc721CreatorTokenAddresses",
  //       args: [address],
  //     });

  //     // Filter tokens where user is still creator
  //     const erc20Tokens = await Promise.all(
  //       erc20Result.map(async (tokenAddress) => {
  //         const isCreator = await readContract({
  //           address: launchpadContractAddress,
  //           abi: [], // ABI for isCreatorOf
  //           functionName: "isCreatorOf",
  //           args: [tokenAddress, address],
  //         });

  //         if (isCreator) {
  //           // Get token details
  //           const name = await readContract({
  //             address: tokenAddress,
  //             abi: [], // ERC20 ABI for name
  //             functionName: "name",
  //           });

  //           const symbol = await readContract({
  //             address: tokenAddress,
  //             abi: [], // ERC20 ABI for symbol
  //             functionName: "symbol",
  //           });

  //           return { address: tokenAddress, name, symbol, type: "ERC20" };
  //         }
  //         return null;
  //       })
  //     );

  //     // Similar process for ERC721 tokens
  //     const erc721Tokens = await Promise.all(
  //       erc721Result.map(async (tokenAddress) => {
  //         // Similar code as above but for ERC721
  //         // ...
  //       })
  //     );

  //     setUserTokens({
  //       erc20: erc20Tokens.filter(Boolean),
  //       erc721: erc721Tokens.filter(Boolean),
  //     });
  //   } catch (error) {
  //     console.error("Failed to fetch user tokens:", error);
  //   } finally {
  //     setIsLoadingTokens(false);
  //   }
  // };

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
          ) : (
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
