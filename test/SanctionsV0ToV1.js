const { expect } = require('chai');

let sanctionsProxy;

describe('SanctionsV0', function () {
    beforeEach(async function () {
        let SanctionsFactoryV0 = await ethers.getContractFactory("SanctionsUpgradeableV0");
        sanctionsProxy = await upgrades.deployProxy(SanctionsFactoryV0);

        let SanctionsFactoryV1 = await ethers.getContractFactory("SanctionsUpgradeableV1");
        sanctionsProxy = await upgrades.upgradeProxy(sanctionsProxy.address, SanctionsFactoryV1)
        //sanctionsV0 = await SanctionsFactory.deploy();
        //await sanctionsV0.deployed();
    });

    it('gets the name correct', async function () {
        let name = await sanctionsProxy.name();
        expect(name).to.equal("Sanctions");
    });
    
    it('returns the latest version number', async function () {        
        expect((await sanctionsProxy.versionNumber()).toString()).to.equal('1');
    });
});
