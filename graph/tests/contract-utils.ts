import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  Erc20TokenCreated,
  Erc721TokenCreated,
  TokenOwnershipTransferred
} from "../generated/Contract/Contract"

export function createErc20TokenCreatedEvent(
  creator: Address,
  tokenAddress: Address,
  name: string,
  symbol: string,
  quantity: BigInt
): Erc20TokenCreated {
  let erc20TokenCreatedEvent = changetype<Erc20TokenCreated>(newMockEvent())

  erc20TokenCreatedEvent.parameters = new Array()

  erc20TokenCreatedEvent.parameters.push(
    new ethereum.EventParam("creator", ethereum.Value.fromAddress(creator))
  )
  erc20TokenCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenAddress",
      ethereum.Value.fromAddress(tokenAddress)
    )
  )
  erc20TokenCreatedEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  erc20TokenCreatedEvent.parameters.push(
    new ethereum.EventParam("symbol", ethereum.Value.fromString(symbol))
  )
  erc20TokenCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "quantity",
      ethereum.Value.fromUnsignedBigInt(quantity)
    )
  )

  return erc20TokenCreatedEvent
}

export function createErc721TokenCreatedEvent(
  creator: Address,
  tokenAddress: Address,
  name: string,
  symbol: string
): Erc721TokenCreated {
  let erc721TokenCreatedEvent = changetype<Erc721TokenCreated>(newMockEvent())

  erc721TokenCreatedEvent.parameters = new Array()

  erc721TokenCreatedEvent.parameters.push(
    new ethereum.EventParam("creator", ethereum.Value.fromAddress(creator))
  )
  erc721TokenCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenAddress",
      ethereum.Value.fromAddress(tokenAddress)
    )
  )
  erc721TokenCreatedEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  erc721TokenCreatedEvent.parameters.push(
    new ethereum.EventParam("symbol", ethereum.Value.fromString(symbol))
  )

  return erc721TokenCreatedEvent
}

export function createTokenOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address,
  tokenAddress: Address
): TokenOwnershipTransferred {
  let tokenOwnershipTransferredEvent =
    changetype<TokenOwnershipTransferred>(newMockEvent())

  tokenOwnershipTransferredEvent.parameters = new Array()

  tokenOwnershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  tokenOwnershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )
  tokenOwnershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "tokenAddress",
      ethereum.Value.fromAddress(tokenAddress)
    )
  )

  return tokenOwnershipTransferredEvent
}
