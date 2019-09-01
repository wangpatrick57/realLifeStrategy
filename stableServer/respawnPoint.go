package main

import (
    "sync"
)

type RespawnPoint struct {
    Lat float64
    Long float64
    Mutex sync.Mutex //lock this for actions regarding lat and long
}

func (respawnPoint *RespawnPoint) getLoc() (float64, float64) {
    respawnPoint.mutexLock()
    return respawnPoint.Lat, respawnPoint.Long
}

func (respawnPoint *RespawnPoint) setLoc(lat, long float64) {
    respawnPoint.mutexLock()
    respawnPoint.Lat = lat
    respawnPoint.Long = long
}

func (respawnPoint *RespawnPoint) getLat() float64 {
    respawnPoint.mutexLock()
    return respawnPoint.Lat
}

func (respawnPoint *RespawnPoint) setLat(lat float64) {
    respawnPoint.mutexLock()
    respawnPoint.Lat = lat
}

func (respawnPoint *RespawnPoint) getLong() float64 {
    respawnPoint.mutexLock()
    return respawnPoint.Long
}

func (respawnPoint *RespawnPoint) setLong(long float64) {
    respawnPoint.mutexLock()
    respawnPoint.Long = long
}

func (respawnPoint *RespawnPoint) mutexLock() {
    respawnPoint.Mutex.Lock()
    defer respawnPoint.Mutex.Unlock()
}
