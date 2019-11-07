package main

import (
    "sync"
)

type RespawnPoint struct {
    Index int
    Lat float64
    Long float64
    Mutex sync.Mutex //lock this for actions regarding lat and long
}

func (respawnPoint *RespawnPoint) getIndex() int {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    return respawnPoint.Index
}

func (respawnPoint *RespawnPoint) setIndex(index int) {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    respawnPoint.Index = index
}

func (respawnPoint *RespawnPoint) getLoc() (float64, float64) {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    return respawnPoint.Lat, respawnPoint.Long
}

func (respawnPoint *RespawnPoint) setLoc(lat, long float64) {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    respawnPoint.Lat = lat
    respawnPoint.Long = long
}

func (respawnPoint *RespawnPoint) getLat() float64 {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    return respawnPoint.Lat
}

func (respawnPoint *RespawnPoint) setLat(lat float64) {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    respawnPoint.Lat = lat
}

func (respawnPoint *RespawnPoint) getLong() float64 {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    return respawnPoint.Long
}

func (respawnPoint *RespawnPoint) setLong(long float64) {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
    respawnPoint.Long = long
}
