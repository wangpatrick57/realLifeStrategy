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
)

const (
    HostName = "10.0.1.128"
    Port = "8888"
    ConnType = "tcp"
)

var connToClient map[*net.Conn]*Client
var master *Master
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
                    idTaken := master.checkIDTaken(readGameID)

                    if (!idTaken) { //fix this so that a new game isn't created when trying to join
                        thisGame := &Game{}
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
                        client.setPlayer(&(Player{}))
                        thisGame := client.getGame()
                        client.getPlayer().constructor(thisGame.getPlayers())
                        thisGame.addPlayer(client.getPlayer())
                        client.getPlayer().setName(readName)
                    }

                    writeString = fmt.Sprintf("checkName:%s:%t:", readName, nameTaken)
                }
            case "rec":
                client.setReceiving(true)
            case "team":
                client.getPlayer().makeSendTrue("team", client.getGame().getPlayers())
                var team = info[posInSlice + 1]
                client.getPlayer().setTeam(team)
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
                client.getPlayer().makeSendTrue("ward", client.getGame().getPlayers())
                lat, err1 := strconv.ParseFloat(info[posInSlice + 1], 64)
                long, err2 := strconv.ParseFloat(info[posInSlice + 2], 64)

                if (err1 == nil && err2 == nil) {
                    client.getPlayer().setWardLoc(lat, long)
                } else {
                    fmt.Printf("error updating ward location. lat %v long %v\n", err1, err2)
                }
            case "dead":
                client.getPlayer().makeSendTrue("dead", client.getGame().getPlayers())
                dead, err := strconv.ParseBool(info[posInSlice + 1])

                if (err == nil) {
                    client.getPlayer().setDead(dead)
                } else {
                    fmt.Printf("error updating dead: %v\n", err)
                }
            case "ret":
                //client.getGame().removePlayer(client.getPlayer())
            }

            posInSlice += posInc[bufType]
            fmt.Printf("posInSlice: %d, len(info): %d, info: %v\n", posInSlice, len(info), info)
        }

        jsonString, _ := json.MarshalIndent(*master, "", " ")
        fmt.Printf("%s\n", string(jsonString))

        if (writeString != "blank") {
            fmt.Printf("Wrote %s\n", writeString)
            conn.Write([]byte(writeString))
        }

        if err != nil {
            fmt.Printf("Error reading: %v\n", err.Error())
            os.Exit(1)
        }

        time.Sleep(100 * time.Millisecond)
    }

    connToClient[&conn] = nil
    conn.Close()
    return
}

func broadcast() {
    for {
        for recConn, recClient := range connToClient {
            if !recClient.getReceiving() {
                continue
            }

            recPlayer := recClient.getPlayer()

            for _, thisPlayer := range recClient.getGame().getPlayers() {
                if (recClient.getReceivingInitial()) {
                    writeString := recClient.getGame().rpString()
                    write(recConn, recClient, writeString)
                }

                if thisPlayer.getLat() != 0 && thisPlayer.getLong() != 0 {
                    var writeString string

                    if recClient.getReceivingInitial() {
                        writeString = thisPlayer.initialPlayerString()
                    } else {
                        writeString = fmt.Sprintf("loc:%s:%f:%f:", thisPlayer.getName(), thisPlayer.getLat(), thisPlayer.getLong())

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

        time.Sleep(1 * time.Second)
    }
}

func write(conn *net.Conn, client *Client, writeString string) {
    _, err := (*conn).Write([]byte(writeString))

    if err != nil {
        fmt.Printf("error writing: %v\n", err)
    } else {
        fmt.Printf("wrote %s to %s\n", writeString, client.getPlayer().getName())
    }
}

func baseMaster() *Master {
    return &Master {
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
