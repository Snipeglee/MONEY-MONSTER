module.exports = {
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    networks: {
        development: {
            gas: 8000000,
            gasPrice:2000000000,
            host: "127.0.0.1",
            port: 8545,
            network_id: "*" // Match any network id
        }
    }

};

