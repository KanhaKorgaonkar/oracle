const hardhat = require("hardhat");
const axios = require("axios");
const MAX_RETIRES = 5;
const SLEEP_TIME = 2000;
const BATCH_SIZE = 3;
async function requestRandomNumber(){
    const res = await axios({
        url: "https://www.random.org/integers/",
        params: {
            num: 1,
            min: 1,
            max: 1000, 
            col: 1,
            base: 10,
            format: "plain",
            rnd: "new",
        },
        method: "get",
    });
    return parseInt(res.data);
}
async function main() {
    // to get ethereum accounts associated with a wallet
    const [dataProvider] = await hardhat.ethers.getSigners();
    // init a contract object 
    const oracleContractAddress = "ORACLE-CONTRACT-ADDRESS-HERE";
    // ABI - Application Binary Interface. 
    const oracleContractABI = require("./randOracleABI.json");
    const oracleContract = new hardhat.ethers.Contract(
        oracleContractAddress, oracleContractABI, dataProvider
    );
    // empty request queue 
    var requestsQueue = [];
    oracleContract.on("RandomNumberRequested", async (callerAddress, id) => {
    requestsQueue.push({ callerAddress, id });
    setInterval(async () => {
        let processedRequests = 0;
        while (requestsQueue.length > 0 && processedRequests < BATCH_SIZE) {
            const request = requestsQueue.shift();
            let retries = 0;
            while (retries < MAX_RETRIES) {
                try {
                    const randomNumber = await requestRandomNumber();
                    await oracleContract.returnRandomNumber(
                        randomNumber,
                        request.callerAddress,
                        request.id
                    );
                    break;
                } catch (error) {
                retries++;
            }
        }
    processedRequests++;
        }
    }, SLEEP_TIME);
}
main();