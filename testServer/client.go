package main

import (
    "sync"
)

type Client struct {
    UUID string
    Game *Game
    Player *Player
    Receiving bool
    ReceivingBP []bool
    ReceivingRP []bool
    Channel chan string
    SimClient bool
    Mutex sync.Mutex //lock this for actions regarding receiving, game, or player
}

func (client *Client) getUUID() string {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    return client.UUID
}

func (client *Client) setUUID(uuid string) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    client.UUID = uuid
}

func (client *Client) getGame() *Game {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    return client.Game
}

func (client *Client) setGame(game *Game) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    client.Game = game
}

func (client *Client) getPlayer() *Player {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    return client.Player
}

func (client *Client) setPlayer(player *Player) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    client.Player = player
}

func (client *Client) getReceiving() bool {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    return client.Receiving
}

func (client *Client) setReceiving(receiving bool) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    client.Receiving = receiving
}

func (client *Client) getReceivingBP(index int) bool {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()

    if (index < len(client.ReceivingBP)) {
        return client.ReceivingBP[index]
    }

    //return false as default (this might be bad design)
    return false
}

func (client *Client) setReceivingBP(index int, receivingBP bool) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()

    for (len(client.ReceivingBP) <= index) {
        client.ReceivingBP = append(client.ReceivingBP, true) //append true because if the index doesn't exist
            //you know that you need to send that borderPoint to the client
    }

    client.ReceivingBP[index] = receivingBP
}

func (client *Client) getReceivingRP(index int) bool {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()

    if (index < len(client.ReceivingRP)) {
        return client.ReceivingRP[index]
    }

    //return false as default (this might be bad design)
    return false
}

func (client *Client) setReceivingRP(index int, receivingRP bool) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()

    for (len(client.ReceivingRP) <= index) {
        client.ReceivingRP = append(client.ReceivingRP, true) //append true because if the index doesn't exist
            //you know that you need to send that borderPoint to the client
    }

    client.ReceivingRP[index] = receivingRP
}

func (client *Client) getChannel() chan string {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    return client.Channel
}

func (client *Client) setChannel(channel chan string) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    client.Channel = channel
}

func (client *Client) getSimClient() bool {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    return client.SimClient
}

func (client *Client) setSimClient(simClient bool) {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
    client.SimClient = simClient
}

func (client *Client) playerDisconnectActions() {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()

    //dcing player has to come before trying clean because the player has to be dc-ed when trying clean
    if (client.Player != nil) {
        client.Player.setConnected(false)
        client.Player.makeSendTrue("dc", client.Game.getPlayerNames())
        client.Player = nil
    }

    if (client.Game != nil) {
        client.Game.tryClean()
    }
}
