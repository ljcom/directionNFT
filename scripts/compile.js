async function main() {
    console.log("⏳ Compiling contracts...");
    await hre.run('compile');
    console.log("✅ Compilation complete.");
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });