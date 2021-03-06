# 👧 tangi

ತಂಗಿ [tangi] [Kan.](https://en.wikipedia.org/wiki/Kannada) younger sister  
ಅಕ್ಕ [akka] [Kan.](https://en.wikipedia.org/wiki/Kannada) older sister

Lightweight actor library for Web Workers inspired by [Akka](https://doc.akka.io).

## What is this?

Type-safe, production-ready and lightweight messaging layer for Web Workers.

Best served with:
 - https://github.com/webpack-contrib/worker-loader

## Why?

For people to scale Web Workers beyond the simple patterns of communication.

## Basic usage

**messages.ts**
```typescript
type PingMessage = {
  _tag: "PING";
}

type PongMessage = {
  _tag: "PONG";
}
```

**main.ts**
```typescript
import { makeActorContext } from "tangi";
import { PingMessage, PongMessage } from "./messages";

const worker = new (require("worker-loader!./worker"))();
const workerRemoteContext = makeActorContext<PingMessage, never>(worker);
const response = await workerRemoteContext.ask<string, PongMessage>(id => ({ _tag: "PING", id }));
switch (response._tag) {
  case "Right": {  
    console.log(response.right);
  }
  case "Left": {  
    console.error(response.left);
  }
}
```

**worker.ts**
```typescript
import { makeActorContext, REPLY } from "tangi";
import { PongMessage } from "./messages";

const workerLocalContext = makeActorContext<never, PongMessage>(globalThis as any);
workerLocalContext.receiveMessage(message => {
  switch (message._tag) {
    case "PING": {
      message[REPLY]({ _tag: "PONG" });
      return;
    }  
  }
});
```


## Interaction patterns

#### Fire and forget

Use `workerRemoteContext.tell({ _tag: "FIRE" })`. See example below:

**messages.ts**
```typescript
type PingMessage = {
  _tag: "PING";
}

type PongMessage = {
  _tag: "PONG";
}
```

**main.ts**
```typescript
import { makeActorContext } from "tangi";

type FireMessage = {
  _tag: "FIRE";
}

const worker = new (require("worker-loader!./worker"))();
const workerRemoteContext = makeActorContext<FireMessage, never>(worker);
workerRemoteContext.tell({ _tag: "FIRE" });
```

#### Request-response

Use `workerRemoteContext.ask({ _tag: "PING" })` combined with `workerLocalContext.receiveMessage({ _tag: "PING" })`. See example below:

**messages.ts**
```typescript
type PingMessage = {
  _tag: "PING";
}

type PongMessage = {
  _tag: "PONG";
}
```

**main.ts**
```typescript
import { makeActorContext } from "tangi";
import { PingMessage, PongMessage } from "./messages";

const worker = new (require("worker-loader!./worker"))();
const workerRemoteContext = makeActorContext<PingMessage, never>(worker);
const response = await workerRemoteContext.ask<string, PongMessage>(id => ({ _tag: "PING", id }));
console.log(response)
```

**worker.ts**
```typescript
import { makeActorContext, REPLY } from "tangi";
import { PongMessage } from "./messages";

const workerLocalContext = makeActorContext<never, PongMessage>(globalThis as any);
workerLocalContext.receiveMessage(message => {
  switch (message._tag) {
    case "PING": {
      message[REPLY]({ _tag: "PONG" });
      return;
    }  
  }
});
```

#### Cancellation (single message)

**worker.ts**
```typescript
import { makeActorContext, REPLY, makeCancellationOperator } from "tangi";

type PingMessage = {
  _tag: "PING";
  id: string;
}

type CancelMessage = {
  _tag: "CANCEL";
  id: string;
}

const makeCancellableTask = () => {
  let isCancelled = false;
  return {
    promise: async () => {
      for (let i = 0; i < 100000; i++) {
        await fetch("http://example.org");
        if (isCancelled) {
          return;
        }
      } 
    },
    cancel: () => {
      isCancelled = true;
    }
  }
};

const workerLocalContext = makeActorContext<never, PongMessage>(globalThis as any);
const cancellationOperator = makeCancellationOperator();
workerLocalContext.receiveMessage(async message => {
  switch (message._tag) {
    case "PING": {
      const task = makeCancellableTask();
      cancellationOperator.register(message.id, message.id, task);
      await task.promise();
      cancellationOperator.unregister(message.id, message.id);
      return;
    }
    case "CANCEL": {
      cancellationOperator.cancel(message.id);
      return;
    }
  }
});
```

#### Cancellation (message groups)

Use it to cancel multiple messages in a given group/context.

Similar to [Cancellation (single message)](#cancellation-single-message) and:
 - types become:
```typescript
type PingMessage = {
  _tag: "PING";
  groupId: string;
  id: string;
}

type CancelMessage = {
  _tag: "CANCEL";
  groupId: string;
  id: string;
}
```
- cancellation operator calls change to:
```typescript
cancellationOperator.register(message.contextId, message.id, task);
      
cancellationOperator.unregister(message.contextId, message.id);
      
cancellationOperator.cancel(message.contextId);
```

## License

[Blue Oak Model License](https://blueoakcouncil.org/license/1.0.0)
