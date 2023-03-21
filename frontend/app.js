App = {
  callerAddress: "FILL-ME-IN",
  callerContract: null,

  init: async function () {
      if (window.ethereum) {
            await window.ethereum.request({ method: 'eth_requestAccounts'});
            window.web3 = new Web3(window.ethereum);
            App.callerContract = new web3.eth.Contract(callerABI, callerAddress);
            App.switchToReplitTestnet();
        }
      App.subscribeToContractEvents();
      App.bindBrowserEvents();
  },
  switchToReplitTestnet: function() {
        window.ethereum.request({
            method: "wallet_addEthereumChain",
            params: [
                {
                    chainId: "0x7265706c",
                    chainName: "Replit Testnet",
                    rpcUrls: ["https://eth.replit.com"],
                    iconUrls: [
                        "https://upload.wikimedia.org/wikipedia/commons/b/b2/Repl.it_logo.svg",
                    ],
                    nativeCurrency: {
                        name: "Replit ETH",
                        symbol: "RΞ",
                        decimals: 18,
                    },
                },
            ],
        });
    },
  getRandomNumber: async function() {
        const accounts = await web3.eth.getAccounts();
        const account = accounts[0];
        return (await App.callerContract.methods.getRandomNumber().send({from: account}));
    },
  subscribeToContractEvents: function() {
        App.callerContract.events.RandomNumberRequested(async (err, event) => {
            if (err) console.error('Error on event', err)
            let reqEventLi = document.createElement("li");
            reqEventLi.classList.add("request");
            reqEventLi.innerHTML = `Random number requested, ID: ${event.returnValues.id}`;
            const eventLog = document.getElementById("events");
            eventLog.prepend(reqEventLi);
          });
      
        App.callerContract.events.RandomNumberReceived(async (err, event) => {
            if (err) console.error('Error on event', err)
            let recEventLi = document.createElement("li");
            recEventLi.classList.add("response");
            recEventLi.innerHTML = `Random number received for ID ${event.returnValues.id}: ${event.returnValues.number}`;
            const eventLog = document.getElementById("events");
            eventLog.prepend(recEventLi);
          });
    },
  bindBrowserEvents: function () {
        const requestButton = document.getElementById("request-rand");
        requestButton.addEventListener("click", async function() {
            const transaction = await App.getRandomNumber();
            const requestID = document.getElementById("request-id");
            requestID.innerHTML = `Submitted! Request ID: ${transaction.events.RandomNumberRequested.returnValues.id}`;
        });
    },
};

App.init();