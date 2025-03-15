import {
  Erc20TokenCreated as Erc20TokenCreatedEvent,
  Erc721TokenCreated as Erc721TokenCreatedEvent,
  TokenOwnershipTransferred as TokenOwnershipTransferredEvent
} from "../generated/Contract/Contract"
import {
  Erc20TokenCreated,
  Erc721TokenCreated,
  TokenOwnershipTransferred
} from "../generated/schema"

export function handleErc20TokenCreated(event: Erc20TokenCreatedEvent): void {
  let entity = new Erc20TokenCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.creator = event.params.creator
  entity.tokenAddress = event.params.tokenAddress
  entity.name = event.params.name
  entity.symbol = event.params.symbol
  entity.quantity = event.params.quantity

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleErc721TokenCreated(event: Erc721TokenCreatedEvent): void {
  let entity = new Erc721TokenCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.creator = event.params.creator
  entity.tokenAddress = event.params.tokenAddress
  entity.name = event.params.name
  entity.symbol = event.params.symbol

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTokenOwnershipTransferred(
  event: TokenOwnershipTransferredEvent
): void {
  let entity = new TokenOwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner
  entity.tokenAddress = event.params.tokenAddress

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
