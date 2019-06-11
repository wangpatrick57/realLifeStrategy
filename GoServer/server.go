package main

import (
    "fmt"
    "net"
    "os"
    "bytes"
    "strings"
    "encoding/json"
    "strconv"
    "time"
    "sync"
)

const (
    HostName = "10.0.1.128"
    Port = "8888"
    ConnType = "tcp"
)

type Client struct {
    Game *Game
    Player *Player
    Receiving bool
    ReceivingInitial bool
    Mux sync.Mutex
}

type Master struct {
    Games []*Game
    Mux sync.Mutex
}

type Game struct {
    GameID string
    Players []*Player
    RedPoints int
    BluePoints int
    RespawnPoints []*RespawnPoint
    ControlPoints []*ControlPoint
    Mux sync.Mutex
}

type Player struct {
    Name string
    Lat float64
    Long float64
    WardLat float64
    WardLong float64
    Team string
    Dead bool
    SendTeam bool
    SendWard bool
    SendDead bool
    Mux sync.Mutex
}

type RespawnPoint struct {
    Lat float64
    Long float64
}

type ControlPoint struct {
    Lat float64
    Long float64
    NumRed int
    NumBlue int
}

var connToClient map[*net.Conn]*Client
var master Master
var posInc map[string]int

func main() {
    connToClient = make(map[*net.Conn]*Client)

    posInc = map[string]int {
        "connected": 1,
        "checkID": 2,
        "checkName": 2,
        "rec": 1,
        "team": 2,
        "loc": 3,
        "ward": 3,
        "dead": 2,
    }

    master = baseMaster()
    l, err := net.Listen(ConnType, HostName + ":" + Port)

    if err != nil {
        fmt.Printf("Error listening: %v\n", err.Error())
        os.Exit(1)
    }

    defer l.Close()
    fmt.Printf("Listening on %s:%s\n", HostName, Port)

    for {
        //read data
        conn, err := l.Accept()

        if err != nil {
            fmt.Printf("Error accepting: %v\n", err.Error())
            os.Exit(1)
        }

        go handleRequest(conn)

        //write data
        go broadcast()
    }

    return
}

func handleRequest(conn net.Conn) {
    client := &(Client{})
    connToClient[&conn] = client

    for {
        fmt.Printf("\nServing %s\n", conn.RemoteAddr().String())
        buf := make([]byte, 1024)
        _, err := conn.Read(buf)
        buf = bytes.Trim(buf, "\x00")

		//Check if msg string has content and that it is a msg type
		content := string(buf)
        fmt.Printf("Read %s from %s\n", content, conn.RemoteAddr().String())

		if content == "" {
			continue
		}

		info := strings.Split(content, ":")
        writeString := "blank"
        posInSlice := 0

        for ;posInSlice < len(info) - 1; {
            bufType := info[posInSlice]

            switch bufType {
            case "checkID":
                readGameID := info[posInSlice + 1]

                if (readGameID != "") {
                    idTaken := checkIDTaken(readGameID)

                    if (!idTaken) {
                        newGame(client, readGameID)
                    } else {
                        client.Game = getGame(readGameID)
                    }

                    writeString = fmt.Sprintf("checkID:%s:%t:", readGameID, idTaken)
                }
            case "checkName":
                var readName = info[posInSlice + 1]

                if (readName != "") {
                    nameTaken := checkNameTaken(client, readName)

                    if (!nameTaken) {
                        client.Player = &(Player{})
                        thisGame := client.Game
                        thisGame.Players = append(thisGame.Players, client.Player)
                        client.Player.Name = readName
                    }

                    writeString = fmt.Sprintf("checkName:%s:%t:", readName, nameTaken)
                }
            case "rec":
                client.Receiving = true
            case "team":
                client.Player.SendTeam = true
                var team = info[posInSlice + 1]
                client.Player.Team = team
            case "loc":
                lat, err1 := strconv.ParseFloat(info[posInSlice + 1], 64)
                long, err2 := strconv.ParseFloat(info[posInSlice + 2], 64)

                if (err1 == nil && err2 == nil) {
                    if (client.Player.Lat == 0 && client.Player.Long == 0) {
                        client.ReceivingInitial = true
                    }

                    updateLoc(client, lat, long)
                } else {
                    fmt.Printf("error updating location. lat %v long %v\n", err1, err2)
                }
            case "ward":
                client.Player.SendWard = true
                lat, err1 := strconv.ParseFloat(info[posInSlice + 1], 64)
                long, err2 := strconv.ParseFloat(info[posInSlice + 2], 64)

                if (err1 == nil && err2 == nil) {
                    updateWardLoc(client, lat, long)
                } else {
                    fmt.Printf("error updating ward location. lat %v long %v\n", err1, err2)
                }
            case "dead":
                client.Player.SendDead = true
                dead, err := strconv.ParseBool(info[posInSlice + 1])

                if (err == nil) {
                    updateDead(client, dead)
                } else {
                    fmt.Printf("error updating dead: %v\n", err)
                }
            }

            posInSlice += posInc[bufType]
            fmt.Printf("posInSlice: %d, len(info): %d, info: %v\n", posInSlice, len(info), info)
            time.Sleep(50 * time.Millisecond)
        }

        jsonString, _ := json.MarshalIndent(master, "", " ")
        fmt.Printf("%s\n", string(jsonString))

        if (writeString != "blank") {
            fmt.Printf("Wrote %s\n", writeString)
            conn.Write([]byte(writeString))
        }

        if err != nil {
            fmt.Printf("Error reading: %v\n", err.Error())
            os.Exit(1)
        }
    }

    connToClient[&conn] = nil
    conn.Close()
    return
}

func broadcast() {
    for {
        for recConn, recClient := range connToClient {
            if recClient.Receiving == false {
                continue
            }

            for _, thisPlayer := range recClient.Game.Players {
                thisPlayer.Mux.Lock()

                if (recClient.ReceivingInitial) {
                    writeString := rpString(recClient)
                    write(recConn, recClient, writeString)
                }

                if thisPlayer.Lat != 0 && thisPlayer.Long != 0 {
                    var writeString string

                    if (recClient.ReceivingInitial) {
                        writeString = initialPlayerString(thisPlayer)
                    } else {
                        writeString = fmt.Sprintf("loc:%s:%f:%f:", thisPlayer.Name, thisPlayer.Lat, thisPlayer.Long)

                        if (thisPlayer.SendTeam) {
                            writeString += fmt.Sprintf("team:%s:%s:", thisPlayer.Name, thisPlayer.Team)
                        }

                        if (thisPlayer.SendDead) {
                            writeString += fmt.Sprintf("dead:%s:%t:", thisPlayer.Name, thisPlayer.Dead)
                        }

                        if (thisPlayer.SendWard) {
                            writeString += fmt.Sprintf("ward:%s:%f:%f:", thisPlayer.Name, thisPlayer.WardLat, thisPlayer.WardLong)
                        }
                    }

                    write(recConn, recClient, writeString)

                }

                thisPlayer.Mux.Unlock()
            }

            recClient.Receiving = false
            recClient.ReceivingInitial = false
        }

        time.Sleep(1 * time.Second)
        //resetAllSends()
    }
}

func write(conn *net.Conn, client *Client, writeString string) {
    _, err := (*conn).Write([]byte(writeString))

    if err != nil {
        fmt.Printf("error writing: %v\n", err)
    } else {
        fmt.Printf("wrote %s to %s\n", writeString, client.Player.Name)
    }
}

func initialPlayerString(thisPlayer *Player) string {
    return fmt.Sprintf("loc:%s:%f:%f:team:%s:%s:dead:%s:%t:ward:%s:%f:%f:", thisPlayer.Name, thisPlayer.Lat,
        thisPlayer.Long, thisPlayer.Name, thisPlayer.Team, thisPlayer.Name, thisPlayer.Dead, thisPlayer.Name,
        thisPlayer.WardLat, thisPlayer.WardLong)
}

func rpString(client *Client) string {
    ret := ""

    for _, rp := range client.Game.RespawnPoints {
        ret += fmt.Sprintf("rp:%f:%f:", rp.Lat, rp.Long)
    }

    return ret
}

func resetAllSends() {
    muxLock()

    for _, g := range master.Games {
        for _, p := range g.Players {
            p.SendTeam = false
            p.SendDead = false
            p.SendWard = false
        }
    }
}

func baseMaster() Master {
    return Master {
        Games: []*Game {
            &Game {
                GameID: "Home",

                RespawnPoints: []*RespawnPoint {
                    &RespawnPoint {
                        Lat: 37.32410,
                        Long: -121.98119,
                    },
                },
            },
        },
    }
}

func newGame(client *Client, gameID string) {
    muxLock()

    thisGame := &Game {
        GameID: gameID,
        RedPoints: 0,
        BluePoints: 0,
    }

    master.Games = append(master.Games, thisGame)
    client.Game = thisGame
}

func updateTeam(client *Client, team string) {
    playerMuxLock(client.Player)

    thisPlayer := client.Player
    thisPlayer.Team = team
}

func updateLoc(client *Client, lat, long float64) {
    playerMuxLock(client.Player)

    thisPlayer := client.Player
    thisPlayer.Lat = lat
    thisPlayer.Long = long
}

func updateDead(client *Client, dead bool) {
    playerMuxLock(client.Player)

    thisPlayer := client.Player
    thisPlayer.Dead = dead
}

func updateWardLoc(client *Client, lat, long float64) {
    playerMuxLock(client.Player)

    thisPlayer := client.Player
    thisPlayer.WardLat = lat
    thisPlayer.WardLong = long
}

func getGame(gameID string) *Game {
    muxLock()

    for _, g := range master.Games {
        if (g.GameID == gameID) {
            return g
        }
    }

    fmt.Printf("game %s doesn't exist\n", gameID)
    tmp := Game{}
    return &tmp
}

func getPlayer(game *Game, name string) *Player {
    gameMuxLock(game)

    for i := 0; i < len(game.Players); i++ {
        player := game.Players[i]

        if (player.Name == name) {
            return player
        }
    }

    fmt.Printf("player %s in game %s doesn't exist\n", name, game.GameID)
    tmp := Player{}
    return &tmp
}

func checkIDTaken(idToCheck string) bool {
    muxLock()

    for _, g := range master.Games {
        if g.GameID == idToCheck {
            return true
        }
    }

    return false
}

func checkNameTaken(client *Client, nameToCheck string) bool {
    muxLock()

    thisGame := client.Game

    for _, p := range thisGame.Players {
        if p.Name == nameToCheck {
            return true
        }
    }

    return false
}

func muxLock() {
    master.Mux.Lock()
    defer master.Mux.Unlock()
}

func gameMuxLock(thisGame *Game) {
    thisGame.Mux.Lock()
    defer thisGame.Mux.Unlock()
}

func playerMuxLock(thisPlayer *Player) {
    thisPlayer.Mux.Lock()
    defer thisPlayer.Mux.Unlock()
}
