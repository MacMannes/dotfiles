return {
    { "marilari88/neotest-vitest" },
    { "weilbith/neotest-gradle" },
    {
        "nvim-neotest/neotest",
        opts = function(_, opts)
            local lib = require("neotest.lib")

            opts.adapters = opts.adapters or {}
            opts.adapters["neotest-vitest"] = {
                filter_dir = function(name, rel_path, root)
                    return name ~= "node_modules" and name ~= "integration-tests"
                end,
            }

            local gradle_adapter = require("neotest-gradle")
            local original_build_spec = gradle_adapter.build_spec
            local original_results = gradle_adapter.results

            -- Override results to handle Kotlin internal function name mangling.
            -- JUnit XML reports names like "testFoo$module_test()" which don't match
            -- the clean treesitter position IDs.
            gradle_adapter.results = function(build_specification, result, tree)
                local results = original_results(build_specification, result, tree)

                -- If we got no results, try matching with mangled names stripped
                if vim.tbl_isempty(results) then
                    local xml = require("neotest.lib.xml")
                    local results_dir = build_specification.context.test_resuls_directory
                    local ok, xml_files = pcall(lib.files.find, results_dir, {
                        filter_dir = function(name)
                            return name:sub(-4) == ".xml"
                        end,
                    })
                    if ok then
                        for _, xml_file in ipairs(xml_files) do
                            local content = lib.files.read(xml_file)
                            local parsed = xml.parse(content)
                            local test_suites = type(parsed.testsuite) == "table"
                                    and (parsed.testsuite._attr and { parsed.testsuite } or parsed.testsuite)
                                or {}
                            for _, suite in pairs(test_suites) do
                                local test_cases = type(suite.testcase) == "table"
                                        and (suite.testcase._attr and { suite.testcase } or suite.testcase)
                                    or {}
                                for _, tc in pairs(test_cases) do
                                    -- Strip Kotlin internal mangling ($module_test) and params
                                    local test_name = tc._attr.name:gsub("%b()", ""):gsub("%$.*$", "")
                                    local class_name = tc._attr.classname
                                    local position_id = class_name .. "." .. test_name

                                    for _, position in tree:iter() do
                                        if position and position.id == position_id then
                                            local failure = tc.failure
                                            local status = failure and "failed" or "passed"
                                            results[position.id] = { status = status }
                                            if failure then
                                                results[position.id].short = failure._attr
                                                    and failure._attr.message
                                                results[position.id].errors = {
                                                    { message = failure._attr and failure._attr.message or "" },
                                                }
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                return results
            end

            gradle_adapter.build_spec = function(arguments)
                local result = original_build_spec(arguments)
                if not result then
                    return result
                end

                local position = arguments.tree:data()
                local root_dir = lib.files.match_root_pattern("gradlew")(position.path)

                if root_dir then
                    local relative = position.path:sub(#root_dir + 2)
                    local subproject_name = relative:match("^(.+)/src/")
                    local gradle_executable = root_dir .. lib.files.sep .. "gradlew"
                    -- Append wildcard to method-level filters to handle Kotlin internal
                    -- functions whose names get mangled in bytecode
                    local test_filter = result.command:match("(%-%-tests .+)$") or ""
                    if position.type == "test" then
                        test_filter = test_filter:gsub("'$", "*'")
                    end

                    local gradle_task
                    if subproject_name and subproject_name ~= "" then
                        gradle_task = ":" .. subproject_name:gsub("/", ":") .. ":test"
                    else
                        gradle_task = ":test"
                    end

                    result.command = gradle_executable
                        .. " --project-dir "
                        .. root_dir
                        .. " "
                        .. gradle_task
                        .. " "
                        .. test_filter
                end

                return result
            end

            table.insert(opts.adapters, gradle_adapter)
        end,
    },
}
