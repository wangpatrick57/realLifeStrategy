package main

import (
    "sync"
)

type Client struct {
    Game *Game
    Player *Player
    Receiving bool
    ReceivingBorder bool
    ReceivingRP bool
    Channel chan string
    SimClient bool
    Mutex sync.Mutex //lock this for actions regarding receiving, game, or player
}

func (client *Client) getGame() *Game {
    client.mutexLock()
    return client.Game
}

func (client *Client) setGame(game *Game) {
    client.mutexLock()
    client.Game = game
}

func (client *Client) getPlayer() *Player {
    client.mutexLock()
    return client.Player
}

func (client *Client) setPlayer(player *Player) {
    client.mutexLock()
    client.Player = player
}

func (client *Client) getReceiving() bool {
    client.mutexLock()
    return client.Receiving
}

func (client *Client) setReceiving(receiving bool) {
    client.mutexLock()
    client.Receiving = receiving
}

func (client *Client) getReceivingBorder() bool {
    client.mutexLock()
    return client.ReceivingBorder
}

func (client *Client) setReceivingBorder(receivingBorder bool) {
    client.mutexLock()
    client.ReceivingBorder = receivingBorder
}

func (client *Client) getReceivingRP() bool {
    client.mutexLock()
    return client.ReceivingRP
}

func (client *Client) setReceivingRP(receivingRP bool) {
    client.mutexLock()
    client.ReceivingRP = receivingRP
}

func (client *Client) getChannel() chan string {
    client.mutexLock()
    return client.Channel
}

func (client *Client) setChannel(channel chan string) {
    client.mutexLock()
    client.Channel = channel
}

func (client *Client) getSimClient() bool {
    client.mutexLock()
    return client.SimClient
}

func (client *Client) setSimClient(simClient bool) {
    client.mutexLock()
    client.SimClient = simClient
}

func (client *Client) playerDisconnectActions() {
    client.mutexLock()

    //dcing player has to come before trying clean because the player has to be dc-ed when trying clean
    if (client.Player != nil) {
        client.Player.setConnected(false)
        client.Player.makeSendTrue("dc", client.Game.getPlayers())
        client.Player = nil
    }

    if (client.Game != nil) {
        client.Game.tryClean()
    }
}

func (client *Client) mutexLock() {
    client.Mutex.Lock()
    defer client.Mutex.Unlock()
}
