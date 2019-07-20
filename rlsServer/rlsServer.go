//stuff to fix: don't create a new game when client tries to join one that doesn't exist

package main

import (
    "fmt"
    "net"
    "os"
    "bytes"
    "strings"
    "encoding/json"
    "io/ioutil"
    "strconv"
    "time"
    "sync"
)

const (
    HostName = "10.0.1.128"
    //HostName = "10.21.129.1"
    Port = "8888"
    ConnType = "tcp"
)

var connToClient map[*net.Conn]*Client
var master *Master
var posInc map[string]int
var mutex sync.Mutex //lock this with actions regarding connToClient

func main() {
    mutex.Lock()
    connToClient = make(map[*net.Conn]*Client)
    mutex.Unlock()

    posInc = map[string]int {
        "hrt": 1,
        "connected": 1,
        "toggleRDL": 1,
        "checkID": 2,
        "checkName": 2,
        "rec": 1,
        "team": 2,
        "loc": 3,
        "ward": 3,
        "dead": 2,
        "ret": 1,
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
    mutex.Lock()
    connToClient[&conn] = client
    mutex.Unlock()
    rdlEnabled := true

    for {
        fmt.Printf("\nServing %s\n", conn.RemoteAddr().String())
        buf := make([]byte, 1024)

        if (rdlEnabled) {
            conn.SetReadDeadline(time.Now().Local().Add(time.Second * time.Duration(10)))
        }

        _, err := conn.Read(buf)
        buf = bytes.Trim(buf, "\x00")
		content := string(buf)
        fmt.Printf("Read %s from %s\n", content, conn.RemoteAddr().String())

        if err != nil {
            fmt.Printf("Error reading: %v\n", err.Error())
            client.playerDisconnectActions()
            return
        }

		info := strings.Split(content, ":")
        writeString := ""
        posInSlice := 0

        for ;posInSlice < len(info) - 1; {
            bufType := info[posInSlice]

            switch bufType {
            case "hrt":
                writeString = "bt:"
            case "connected": //why is connected used
            case "toggleRDL":
                rdlEnabled = !rdlEnabled

                if (!rdlEnabled) {
                    conn.SetReadDeadline(time.Time{})
                }
            case "checkID":
                readGameID := info[posInSlice + 1]

                if (readGameID != "") {
                    idTaken := master.checkIDTaken(readGameID)

                    if (!idTaken) { //fix this so that a new game isn't created when trying to join a nonexisting game
                        thisGame := &Game{}
                        thisGame.constructor()
                        thisGame.setGameID(readGameID)
                        master.addGame(thisGame)
                        client.setGame(thisGame)
                    } else {
                        client.setGame(master.getGame(readGameID))
                    }

                    writeString = fmt.Sprintf("checkID:%s:%t:", readGameID, idTaken)
                }
            case "checkName":
                var readName = info[posInSlice + 1]

                if (readName != "") {
                    nameTaken := client.getGame().checkNameTaken(readName)

                    if (!nameTaken) {
                        thisPlayer := &(Player{})
                        client.setPlayer(thisPlayer)
                        thisGame := client.getGame()
                        thisPlayer.constructor(thisGame.getPlayers())
                        thisPlayer.setName(readName)
                        thisGame.addPlayer(thisPlayer)
                    }

                    writeString += fmt.Sprintf("checkName:%s:%t:", readName, nameTaken)
                }
            case "rec":
                client.setReceiving(true)
            case "team":
                var team = info[posInSlice + 1]
                client.getPlayer().setTeam(team)
                client.getPlayer().makeSendTrue("team", client.getGame().getPlayers())
            case "loc":
                lat, err1 := strconv.ParseFloat(info[posInSlice + 1], 64)
                long, err2 := strconv.ParseFloat(info[posInSlice + 2], 64)

                if (err1 == nil && err2 == nil) {
                    if (client.getPlayer().getLat() == 0 && client.getPlayer().getLong() == 0) {
                        client.setReceivingInitial(true)
                    }

                    client.getPlayer().setLoc(lat, long)
                } else {
                    fmt.Printf("error updating location. lat %v long %v\n", err1, err2)
                }
            case "ward":
                lat, err1 := strconv.ParseFloat(info[posInSlice + 1], 64)
                long, err2 := strconv.ParseFloat(info[posInSlice + 2], 64)

                if (err1 == nil && err2 == nil) {
                    client.getPlayer().setWardLoc(lat, long)
                } else {
                    fmt.Printf("error parsing ward location. lat %v long %v\n", err1, err2)
                }

                client.getPlayer().makeSendTrue("ward", client.getGame().getPlayers())
            case "dead":
                dead, err := strconv.ParseBool(info[posInSlice + 1])

                if (err == nil) {
                    client.getPlayer().setDead(dead)
                } else {
                    fmt.Printf("error updating dead: %v\n", err)
                }

                client.getPlayer().makeSendTrue("dead", client.getGame().getPlayers())
            case "ret":
                client.playerDisconnectActions()
            }

            posInSlice += posInc[bufType]
        }

        if (writeString != "") {
            fmt.Printf("Wrote %s\n", writeString)
            write(&conn, client, writeString)
        }
    }

    mutex.Lock()
    connToClient[&conn] = nil
    mutex.Unlock()
    conn.Close()
    return
}

func broadcast() {
    for {
        mutex.Lock()
        
        for recConn, recClient := range connToClient {
            if !recClient.getReceiving() {
                continue
            }

            if (recClient.getReceivingInitial()) {
                writeString := recClient.getGame().rpString()
                write(recConn, recClient, writeString)
            }

            recPlayer := recClient.getPlayer()

            for _, thisPlayer := range recClient.getGame().getPlayers() {
                //checking that their position isn't 0,0 ensures they are in game
                if thisPlayer != recClient.getPlayer() && thisPlayer.getLat() != 0 && thisPlayer.getLong() != 0 {
                    writeString := ""

                    //receivingInitial is for players who just joined the game to get the current game state
                    //sendTo arrays is for players already in the game to broadcast their changed info to all other players
                    if recClient.getReceivingInitial() {
                        writeString = thisPlayer.initialPlayerString()
                    } else {
                        if (thisPlayer.getConnected()) {
                            writeString += fmt.Sprintf("loc:%s:%f:%f:", thisPlayer.getName(), thisPlayer.getLat(), thisPlayer.getLong())
                        }

                        //conn has to be before everything because when conn is true the client creates a new player
                        if val, ok := thisPlayer.getSendTo("conn", recPlayer.getName()); ok && val {
                            writeString += fmt.Sprintf("conn:%s:%t:", thisPlayer.getName(), thisPlayer.getConnected())
                            thisPlayer.setSendTo("conn", recPlayer.getName(), false)
                        }

                        //team has to be before ward so the ward is drawn with the team known
                        if val, ok := thisPlayer.getSendTo("team", recPlayer.getName()); ok && val {
                            writeString += fmt.Sprintf("team:%s:%s:", thisPlayer.getName(), thisPlayer.getTeam())
                            thisPlayer.setSendTo("team", recPlayer.getName(), false)
                        }

                        if val, ok := thisPlayer.getSendTo("ward", recPlayer.getName()); ok && val {
                            writeString += fmt.Sprintf("ward:%s:%f:%f:", thisPlayer.getName(), thisPlayer.getWardLat(), thisPlayer.getWardLong())
                            thisPlayer.setSendTo("ward", recPlayer.getName(), false)
                        }

                        if val, ok := thisPlayer.getSendTo("dead", recPlayer.getName()); ok && val {
                            writeString += fmt.Sprintf("dead:%s:%t:", thisPlayer.getName(), thisPlayer.getDead())
                            thisPlayer.setSendTo("dead", recPlayer.getName(), false)
                        }
                    }

                    write(recConn, recClient, writeString)
                }
            }

            recClient.setReceiving(false)
            recClient.setReceivingInitial(false)
        }

        //writing to json file is here so that it's done regularly regardless of disconnects
        jsonFile, err := json.MarshalIndent(*master, "", " ")

        if (err == nil) {
            err = ioutil.WriteFile("master.json", jsonFile, 0644)

            if (err != nil) {
                fmt.Printf("Error writing json file: %v\n", err)
            }
        } else {
            fmt.Printf("Error converting master to json: %v\n", err)
        }

        mutex.Unlock()
        time.Sleep(1 * time.Second)
    }
}

func write(conn *net.Conn, client *Client, writeString string) {
    _, err := (*conn).Write([]byte(writeString))

    if err != nil {
        fmt.Printf("Error writing: %v\n", err)
    } else {
        var idString string

        if (client.getPlayer() != nil) {
            idString = client.getPlayer().getName()
        } else {
            idString = "unknown"
        }

        fmt.Printf("Wrote %s to %s\n", writeString, idString)
    }
}

func baseMaster() *Master {
    ret := &Master {
        Games: map[string]*Game {
            "Home": &Game {
                GameID: "Home",

                RespawnPoints: []*RespawnPoint {
                    &RespawnPoint {
                        Lat: 38.32410,
                        Long: -121.98119,
                    },
                },

                Players: map[string]*Player {},
            },

            /*"DeAnza": &Game {
                GameID: "DeAnza",

                RespawnPoints: []*RespawnPoint {
                    &RespawnPoint {
                        Lat: 37.32032,
                        Long: -122.04449,
                    },
                    &RespawnPoint {
                        Lat: 37.32024,
                        Long: -122.04502,
                    },
                    &RespawnPoint {
                        Lat: 37.31999,
                        Long: -122.04552,
                    },
                    &RespawnPoint {
                        Lat: 37.32111,
                        Long: -122.045907,
                    },
                    &RespawnPoint {
                        Lat: 37.32053,
                        Long: -122.04532,
                    },
                    &RespawnPoint {
                        Lat: 37.32124,
                        Long: -122.04510,
                    },
                },

                Players: map[string]*Player {},
            },*/
        },
    }

    /*blueDummy := &Player{}
    blueDummy.constructor(ret.getGame("Home").getPlayers())
    blueDummy.setName("blueDummy")
    blueDummy.setTeam("blue")
    blueDummy.setLoc(37.32440, -121.98119)
    ret.getGame("Home").addPlayer(blueDummy)*/

    return ret
}
